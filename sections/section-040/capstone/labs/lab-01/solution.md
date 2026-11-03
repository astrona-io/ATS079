# Solution

Step 1 creates the project, step 2 moves staging into it, and step 3 shows the refusal. After each step, `astrona submit` shows which check passes.

## Step 1: Create the project

Save this as `scout-team-project.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: scout-team
  namespace: argocd
spec:
  description: The scout team may deliver to staging only
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet-staging
```

Apply it:

```sh
kubectl apply -f scout-team-project.yaml
```

Check it: run `astrona submit`. The check `project-boundary` passes.

## Step 2: Move staging into the project

The project must exist before the move, because the controller checks the Application against its project. Patch the project of the Application:

```sh
kubectl -n argocd patch application scout-staging --type merge -p '{"spec":{"project":"scout-team"}}'
kubectl -n argocd get application scout-staging -o jsonpath='{.spec.project}{" "}{.status.sync.status}{" "}{.status.health.status}{"\n"}'
```

Check it: the project is `scout-team`, and the Application stays `Synced` and `Healthy`. Run `astrona submit`. The check `staging-in-project` passes.

## Step 3: Show that production is refused

Save this as `scout-production-attempt.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: scout-production-attempt
  namespace: argocd
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
kubectl apply -f scout-production-attempt.yaml
```

Check it: wait about 30 seconds, then read the conditions and the namespace.

```sh
kubectl -n argocd get application scout-production-attempt -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
kubectl -n starfleet-production get deploy,svc
```

The condition `InvalidSpecError` names the project, and the namespace holds no objects. Run `astrona submit`. All three checks pass.

## Why this works

The controller checks every Application against its project each time it compares. A destination that the project does not list is refused before anything is applied, so the automated sync policy has nothing to run. The refusal is a condition on the Application and not an error in Git, which is why the Application stays in the cluster as visible evidence.
