# Question

Solve this question on: `terminal`

The platform team delivers the web service `scout` with Argo CD. The Git repository `starfleet/scout-deploy` on the in-cluster Git server holds the desired state, and the Application `scout-staging` delivers the folder `overlays/staging` to the namespace `starfleet-staging`. Staging runs the image tag 6.14.0. A build has produced the version 6.15.0, and it is your job to promote it to staging and to record the delivery.

Reach Git at `http://127.0.0.1:3000` (user `platform`, password `starfleet-gitops`) and Argo CD at `https://127.0.0.1:8080`.

1. Promote 6.15.0 to staging by changing Git. Do not change the objects in the cluster by hand.
2. Wait until Argo CD has delivered the commit and the environment is healthy.
3. Create the ConfigMap `delivery-record` in the namespace `starfleet` with these keys:
   - `environment`: `staging`
   - `version`: the version that runs, read from the Deployment
   - `commit`: the full commit ID that Argo CD compared, read from the Application
   - `health`: the health status of the Application

When you finish, these must be true:

- `overlays/staging/kustomization.yaml` on the branch `main` sets the image tag to 6.15.0, in a new commit.
- The Application `scout-staging` is `Synced` and `Healthy`, its revision is the head commit of `main`, and the Deployment `scout` in `starfleet-staging` runs `ghcr.io/stefanprodan/podinfo:6.15.0` and is owned by Argo CD.
- The ConfigMap `delivery-record` has the keys above, and `commit` equals the head commit of `main`.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
