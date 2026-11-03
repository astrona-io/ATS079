# Question

Solve this question on: `terminal`

The platform team delivers `scout` to staging with Argo CD. The Git repository `starfleet/scout-deploy` on the in-cluster Git server holds the desired state, and the Application `scout-staging` delivers `overlays/staging` to the namespace `starfleet-staging` with the sync policy `automated: {}`. Before every release of staging, a check must run and must succeed, and the release must stop when the check fails.

Reach Git at `http://127.0.0.1:3000` (user `platform`, password `starfleet-gitops`) and Argo CD at `https://127.0.0.1:8080`.

1. Add a Job named `scout-presync-check` to `overlays/staging`, in the file `scout-presync-check.yaml`. It uses the image `curlimages/curl:8.22.0`, runs `sh -c "echo schema check passed"`, has `restartPolicy: Never` and `backoffLimit: 0`.
2. Make Argo CD run the Job before the manifests are applied, and delete the old Job before a new one is created.
3. List the file in the staging overlay, commit and push to `main`, and wait until Argo CD has run the sync.

When you finish, these must be true:

- `overlays/staging/scout-presync-check.yaml` is a Job with the hook `PreSync` and a hook delete policy of `BeforeHookCreation` or `HookSucceeded`, and `overlays/staging/kustomization.yaml` lists it under `resources`.
- The last sync of `scout-staging` ran `scout-presync-check` as a `PreSync` hook, and its phase is `Succeeded`.
- `scout-staging` is `Synced` and `Healthy` at the head commit of `main`, and `scout` still runs `ghcr.io/stefanprodan/podinfo:6.14.0` with one ready replica.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
