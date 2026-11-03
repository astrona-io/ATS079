# Question

Solve this question on: `terminal`

The platform team delivers `scout` to staging with Argo CD. The Git repository `starfleet/scout-deploy` on the in-cluster Git server holds the desired state, and the Application `scout-staging` delivers `overlays/staging` to the namespace `starfleet-staging`. The last commit on `main`, `bump scout staging to 6.15.99`, set an image tag that does not exist, and the delivery is unhealthy. The Application has the sync policy `automated: {}`.

Reach Git at `http://127.0.0.1:3000` (user `platform`, password `starfleet-gitops`) and Argo CD at `https://127.0.0.1:8080`.

1. Undo the bad release in Git without removing it from the history.
2. Wait until Argo CD has delivered the repair and staging is healthy on the previous version.
3. Change the Application so that Argo CD undoes changes made by hand in the cluster and deletes objects that are removed from Git.

When you finish, these must be true:

- The head commit of `main` is a revert commit, the commit `bump scout staging to 6.15.99` is still in the history, and `overlays/staging/kustomization.yaml` sets the image tag to 6.14.0.
- The Application `scout-staging` is `Synced` and `Healthy`, its revision is the head commit of `main`, and the Deployment `scout` runs `ghcr.io/stefanprodan/podinfo:6.14.0` with one ready replica.
- The Application has automated sync with `prune` and `selfHeal` turned on, and a hand edit of the replica count of `scout` is undone.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
