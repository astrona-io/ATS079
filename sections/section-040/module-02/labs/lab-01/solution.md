# Solution

Step 1 writes the hook Job, step 2 lists it in the overlay and pushes, and step 3 reads the result from Argo CD. After each step, `astrona submit` shows which check passes.

## Step 1: Write the hook Job

Clone the repository:

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
```

Save this as `overlays/staging/scout-presync-check.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: scout-presync-check
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: check
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "echo schema check passed"]
```

The annotation `hook: PreSync` makes Argo CD run the Job before it applies the other objects. The delete policy removes the old Job before a new one is created, so the next sync does not fail on the name.

## Step 2: List the file and push

Add the file under `resources` in `overlays/staging/kustomization.yaml`, below `../../base`:

```yaml
resources:
  - ../../base
  - scout-presync-check.yaml
```

Render it first to check the YAML, then commit and push:

```sh
kubectl kustomize overlays/staging | grep -A3 'kind: Job'
git add -A
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "add presync check to staging"
git push origin main
```

Check it: run `astrona submit`. The check `hook-in-git` passes.

## Step 3: Let Argo CD run the sync

Ask for a refresh and read the hook phase:

```sh
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd get application scout-staging -o jsonpath='{range .status.operationState.syncResult.resources[*]}{.kind}{"\t"}{.name}{"\t"}{.hookType}{"\t"}{.hookPhase}{"\n"}{end}'
```

The Job row shows `PreSync` and `Succeeded`. If the output is empty, wait a few seconds and run it again. Check it: run `astrona submit`. All three checks pass.

## Why this works

The hook is a normal file in Git, so it is reviewed and versioned like the rest. Argo CD runs it before the Deployment is touched and continues only when the Job succeeds. The image tag and the replica count do not change, so the application stays on 6.14.0.
