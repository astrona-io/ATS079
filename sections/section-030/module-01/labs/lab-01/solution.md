# Solution

Step 1 changes Git, step 2 asks Argo CD to deliver it, and step 3 records the outcome. After each step, `astrona submit` shows which check passes.

## Step 1: Promote by commit

Clone the repository:

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
```

Save this as `overlays/staging/kustomization.yaml`:

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

Apply it: commit and push the change.

```sh
git add overlays/staging/kustomization.yaml
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "promote scout to 6.15.0 in staging"
git push origin main
```

Check it: run `astrona submit`. The check `promoted-in-git` passes.

## Step 2: Let Argo CD deliver it

Argo CD polls Git about every three minutes. Ask for a refresh and wait for the rollout:

```sh
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-staging rollout status deploy/scout --timeout=180s
kubectl -n argocd get application scout-staging
```

The Application shows `Synced` and `Healthy`. Check it: run `astrona submit`. The check `delivered-by-argocd` passes.

## Step 3: Write the delivery record

Read the facts from the cluster instead of typing them:

```sh
kubectl -n starfleet create configmap delivery-record \
  --from-literal=environment=staging \
  --from-literal=version="$(kubectl -n starfleet-staging get deploy scout -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d: -f2)" \
  --from-literal=commit="$(kubectl -n argocd get application scout-staging -o jsonpath='{.status.sync.revision}')" \
  --from-literal=health="$(kubectl -n argocd get application scout-staging -o jsonpath='{.status.health.status}')"
```

Check it: run `astrona submit`. All three checks pass.

## Why this works

The Application tracks the folder `overlays/staging` on `main`. A commit changes the rendered manifests, the controller applies the difference, and the Deployment controller performs the rolling update. The revision in the Application status is the commit that was compared, so a record that copies it can be traced back to the exact desired state.
