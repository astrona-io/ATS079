# Question

Solve this question on: `terminal`

The platform team delivers `scout` to two environments with Argo CD. The Git repository `starfleet/scout-deploy` on the in-cluster Git server holds the desired state. The Application `scout-staging` delivers `overlays/staging` to the namespace `starfleet-staging` (one replica), and the Application `scout-production` delivers `overlays/production` to `starfleet-production` (two replicas). Both run the image tag 6.14.0. A build has produced the version 6.15.0.

Reach Git at `http://127.0.0.1:3000` (user `platform`, password `starfleet-gitops`) and Argo CD at `https://127.0.0.1:8080`.

The delivery contract of the team says: production receives a version only after staging has received it and is healthy, and every promotion is its own commit.

1. Promote 6.15.0 to staging in one commit, and wait until staging is delivered and healthy.
2. Promote 6.15.0 to production in a second commit, and wait until production is delivered and healthy.
3. Create the ConfigMap `delivery-record` in the namespace `starfleet` with these keys:
   - `staging-commit`: the full ID of the commit that changed the staging overlay
   - `production-commit`: the full ID of the commit that changed the production overlay
   - `version`: `6.15.0`

Do not change objects in the cluster by hand, and do not change the Applications.

When you finish, these must be true:

- Both overlays on the branch `main` set the image tag to 6.15.0. They changed in two different commits, and the production commit is newer than the staging commit.
- Both Applications are `Synced` and `Healthy` at the head commit, both Deployments run `ghcr.io/stefanprodan/podinfo:6.15.0` and are owned by Argo CD, and production has two ready replicas.
- The ConfigMap `delivery-record` has the keys above.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
