# Solution

Step 1 creates the ApplicationSet with three environments, step 2 promotes the version by two commits and step 3 retires the preview environment by removing its element. After each step, `astrona submit` shows which check passes.

## Step 1: Create the ApplicationSet

Save this as `scout-envs.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: scout-envs
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - list:
        elements:
          - env: staging
          - env: production
          - env: preview
  template:
    metadata:
      name: 'scout-{{.env}}'
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: scout-team
      source:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        targetRevision: main
        path: 'overlays/{{.env}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'starfleet-{{.env}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

Apply it:

```sh
kubectl apply -f scout-envs.yaml
```

Check it: three Applications appear, each owned by the ApplicationSet. Wait until they are `Synced` and `Healthy`.

```sh
kubectl -n argocd get applications
kubectl -n argocd get application scout-preview -o jsonpath='{.metadata.ownerReferences[0].kind}{"\n"}'
```

## Step 2: Promote staging, then production

Clone the repository and change one overlay for each commit.

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
```

Save this as `overlays/staging/kustomization.yaml` in the clone:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: starfleet-staging
resources:
  - ../../base
labels:
  - pairs:
      environment: staging
images:
  - name: ghcr.io/stefanprodan/podinfo
    newTag: 6.15.0
replicas:
  - name: scout
    count: 1
patches:
  - path: message.yaml
```

Commit and push it:

```sh
git add overlays/staging/kustomization.yaml
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "promote scout to 6.15.0 in staging"
git push origin main
```

Save this as `overlays/production/kustomization.yaml` in the clone:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: starfleet-production
resources:
  - ../../base
labels:
  - pairs:
      environment: production
images:
  - name: ghcr.io/stefanprodan/podinfo
    newTag: 6.15.0
replicas:
  - name: scout
    count: 2
patches:
  - path: message.yaml
```

Commit and push it, then ask Argo CD to refresh both Applications so that each one compares the head commit:

```sh
git add overlays/production/kustomization.yaml
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "promote scout to 6.15.0 in production"
git push origin main
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd annotate application scout-production argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-staging rollout status deploy/scout --timeout=180s
kubectl -n starfleet-production rollout status deploy/scout --timeout=180s
```

Check it: both Applications show `Synced` and `Healthy`, and the preview environment is still on 6.14.0. Run `astrona submit`. The check `promoted` passes.

## Step 3: Retire the preview environment

Save this as `scout-envs-final.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: scout-envs
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - list:
        elements:
          - env: staging
          - env: production
  template:
    metadata:
      name: 'scout-{{.env}}'
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: scout-team
      source:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        targetRevision: main
        path: 'overlays/{{.env}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'starfleet-{{.env}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

Apply it:

```sh
kubectl apply -f scout-envs-final.yaml
```

Check it: after a short time the Application `scout-preview` is gone, and, because the template carries the finalizer, the objects in `starfleet-preview` are gone too.

```sh
kubectl -n argocd get applications
kubectl -n starfleet-preview get deploy,svc
kubectl get namespace starfleet-preview
```

Run `astrona submit`. All three checks pass.

## Why this works

The ApplicationSet is the only definition of the environments, so each generated Application has the same shape and the same finalizer. The promotion is two Git commits, and each Application reports the commit that it compared in `status.sync.revision`. Because both Applications read the same repository, each one has to compare the newest commit before it shows the head revision, which is why both are refreshed. Removing the element deletes the Application, and the finalizer in the template makes the deletion remove the objects first. The namespace was created outside the Application, so it stays.
