# Solution

Two commits, one delivery wait after each, and one record. After each step, `astrona submit` shows which check passes.

## Step 1: Promote staging

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

Apply it: commit and push, ask for a refresh and wait until staging is healthy.

```sh
git add overlays/staging/kustomization.yaml
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "promote scout to 6.15.0 in staging"
git push origin main
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-staging rollout status deploy/scout --timeout=180s
```

Check it: `kubectl -n argocd get application scout-staging` shows `Synced` and `Healthy`.

## Step 2: Promote production

Save this as `overlays/production/kustomization.yaml`:

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

Apply it: commit and push in a second commit, ask for a refresh and wait.

```sh
git add overlays/production/kustomization.yaml
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "promote scout to 6.15.0 in production"
git push origin main
kubectl -n argocd annotate application scout-production argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-production rollout status deploy/scout --timeout=180s
```

The staging Application is refreshed as well. Both Applications track `main`, so both must compare the head commit before the check `both-delivered` sees the head revision on each.

Check it: run `astrona submit`. The checks `promotion-order` and `both-delivered` pass.

## Step 3: Write the delivery record

The record names the commit that changed each overlay. In this clone, `git log -1 --format=%H -- <path>` prints it:

```sh
kubectl -n starfleet create configmap delivery-record \
  --from-literal=staging-commit="$(git log -1 --format=%H -- overlays/staging/kustomization.yaml)" \
  --from-literal=production-commit="$(git log -1 --format=%H -- overlays/production/kustomization.yaml)" \
  --from-literal=version=6.15.0
```

Check it: run `astrona submit`. All three checks pass.

## Why this works

Each overlay has its own Application, so each commit moves one environment. Two commits keep the order visible in the history, and the commit that changed an overlay is the exact point in history at which that environment was promoted. A record that names both commits answers the question which commit is running where.
