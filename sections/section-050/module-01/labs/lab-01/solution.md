# Solution

Step 1 creates the project, step 2 creates the staging Application and step 3 creates the production Application. After each step, `astrona submit` shows which check passes.

## Step 1: Create the project

The project lists the repository and the two environments that the team may deliver to. The preview namespace is left out on purpose. Save this as `scout-team.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: scout-team
  namespace: argocd
spec:
  description: The scout team may deliver to staging and production
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet-staging
    - server: https://kubernetes.default.svc
      namespace: starfleet-production
```

Apply it:

```sh
kubectl apply -f scout-team.yaml
```

Check it: run `astrona submit`. The check `project-boundary` passes.

## Step 2: Create the staging Application

Staging has no finalizer, so deleting the Application would leave the objects behind. Save this as `scout-staging.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: scout-staging
  namespace: argocd
spec:
  project: scout-team
  source:
    repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
    targetRevision: main
    path: overlays/staging
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet-staging
  syncPolicy:
    automated: {}
```

Apply it:

```sh
kubectl apply -f scout-staging.yaml
```

Check it: wait until the Application is `Synced` and `Healthy`.

```sh
kubectl -n argocd get application scout-staging
kubectl -n starfleet-staging get deploy scout
```

## Step 3: Create the production Application

Production carries the finalizer, so deleting the Application removes its objects first. Save this as `scout-production.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: scout-production
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: scout-team
  source:
    repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
    targetRevision: main
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet-production
  syncPolicy:
    automated: {}
```

Apply it:

```sh
kubectl apply -f scout-production.yaml
```

Check it: wait until both Applications are `Synced` and `Healthy`, then run `astrona submit`. All three checks pass. The check `preview-refused` creates a temporary Application for the preview overlay and reads its condition.

```sh
kubectl -n argocd get applications
kubectl -n starfleet-production get deploy scout
```

## Why this works

The Application names where the objects come from and where they go. The project is checked each time the controller compares, so a destination that it does not list is refused before anything is applied. The preview Application in the check has the right repository and path, and only the namespace is outside the project, which is why the refusal is the proof of the boundary. The finalizer is part of the Application and not of the project, so each Application chooses its own deletion behavior.
