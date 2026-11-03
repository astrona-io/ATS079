# Question

Solve this question on: `terminal`

The platform team delivers `scout` with Argo CD. The Application `scout-staging` belongs to the project `default`, which allows every repository, every destination and every kind. It delivers `overlays/staging` from the repository `http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git` to the namespace `starfleet-staging`. The namespace `starfleet-production` exists and is empty. The team must not be able to deliver to production from this Argo CD setup.

Reach Argo CD at `https://127.0.0.1:8080`.

1. Create the AppProject `scout-team` in the namespace `argocd`. It allows exactly one repository, the one above, and exactly one destination: the in-cluster server `https://kubernetes.default.svc` with the namespace `starfleet-staging`. Do not use wildcards, and do not allow cluster-scoped kinds.
2. Move the Application `scout-staging` into the project `scout-team`. It must stay delivered and healthy.
3. Create the Application `scout-production-attempt` in the project `scout-team`. It uses the same repository, the path `overlays/production` and the destination namespace `starfleet-production`, with automated sync. Show that the project refuses it.

When you finish, these must be true:

- The AppProject `scout-team` has the one repository and the one destination above, and no wildcard for cluster-scoped kinds.
- `scout-staging` has `spec.project: scout-team`, is `Synced` and `Healthy`, and its Deployment is still tracked by it.
- `scout-production-attempt` exists in the project `scout-team` with the condition `InvalidSpecError`, and `starfleet-production` contains no Deployment and no Service.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
