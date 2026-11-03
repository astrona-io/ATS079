# Question

Solve this question on: `terminal`

The platform team will deliver `scout` to two environments with Argo CD. The Git repository `http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git` holds the overlays `staging`, `production` and `preview`. The namespaces `starfleet-staging`, `starfleet-production` and `starfleet-preview` exist and are empty. No project and no Application exist yet. The team must not be able to deliver to the preview namespace from these Applications.

Reach Argo CD at `https://127.0.0.1:8080`.

1. Create the AppProject `scout-team` in the namespace `argocd`. It allows exactly one repository, the one above, and exactly two destinations: the in-cluster server `https://kubernetes.default.svc` with the namespaces `starfleet-staging` and `starfleet-production`. Do not use wildcards, and do not allow cluster-scoped kinds.
2. Create the Application `scout-staging` in the project `scout-team`. It delivers `overlays/staging` from the branch `main` to `starfleet-staging` with automated sync. It has no finalizer.
3. Create the Application `scout-production` in the project `scout-team`. It delivers `overlays/production` from the branch `main` to `starfleet-production` with automated sync. It has the finalizer `resources-finalizer.argocd.argoproj.io`.

When you finish, these must be true:

- The AppProject `scout-team` has the one repository and the two destinations above, and no wildcard for cluster-scoped kinds.
- Both Applications are `Synced` and `Healthy` at the head commit of `main`. The Deployment `scout` runs `ghcr.io/stefanprodan/podinfo:6.14.0`, with one ready replica in staging and two in production, and each Deployment is tracked by its own Application. Only production has the finalizer.
- An Application for `overlays/preview` in the project `scout-team` is refused with the condition `InvalidSpecError`. The checker creates a temporary Application named `probe-preview` to test this and deletes it again.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
