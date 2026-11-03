# Question

Solve this question on: `terminal`

The platform team wants one definition for all environments of `scout`. The Git repository `http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git` holds the overlays `staging`, `production` and `preview`, all on image `6.14.0`. The project `scout-team` already exists and allows the repository and the namespaces `starfleet-staging`, `starfleet-production` and `starfleet-preview`. No Application and no ApplicationSet exist yet.

Reach Git at `http://127.0.0.1:3000` (user `platform`, password `starfleet-gitops`) and Argo CD at `https://127.0.0.1:8080`.

1. Create the ApplicationSet `scout-envs` in the namespace `argocd`. It uses Go templates and a list generator with the three elements `staging`, `production` and `preview`. The template creates an Application named `scout-<env>` in the project `scout-team`. The Application delivers `overlays/<env>` from the branch `main` to the namespace `starfleet-<env>`, has the finalizer `resources-finalizer.argocd.argoproj.io` and automated sync with `prune` and `selfHeal`. Wait until the three Applications are healthy.
2. Promote the version to `6.15.0` in two commits: first `overlays/staging`, then `overlays/production`. Each commit changes one overlay. The preview overlay stays on `6.14.0`.
3. Retire the preview environment by removing its element from the ApplicationSet. Do not delete the Application by hand.

When you finish, these must be true:

- The ApplicationSet `scout-envs` has a list generator with exactly the elements `staging` and `production`, a template in the project `scout-team` with the finalizer and with `prune` and `selfHeal`, and placeholders in the name, the path and the namespace instead of fixed values. The Applications `scout-staging` and `scout-production` are owned by the ApplicationSet.
- Both overlays name `6.15.0`, the production commit is newer than the staging commit, and both Applications are `Synced` and `Healthy` at the head commit with the Deployment `scout` running `ghcr.io/stefanprodan/podinfo:6.15.0`, with one ready replica in staging and two in production.
- The Application `scout-preview` does not exist, `starfleet-preview` contains no Deployment and no Service, and the namespace itself is still there.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
