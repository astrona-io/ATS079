# Solution

Step 1 reverts the bad commit in Git, step 2 asks Argo CD to deliver the revert, and step 3 makes Argo CD enforce Git. After each step, `astrona submit` shows which check passes.

## Step 1: Revert the bad commit

Clone the repository and read the history:

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
git log --oneline
```

The newest commit is `bump scout staging to 6.15.99`. Revert it, which adds a new commit that applies the opposite change:

```sh
git -c user.name=ci -c user.email=ci@starfleet.local revert --no-edit HEAD
git push origin main
```

Check it: run `astrona submit`. The check `reverted-in-git` passes.

## Step 2: Let Argo CD deliver the revert

Automated sync delivers a new commit, and the polling interval is about three minutes. Ask for a refresh and wait for the rollout:

```sh
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-staging rollout status deploy/scout --timeout=180s
kubectl -n argocd get application scout-staging
```

The Application shows `Synced` and `Healthy`. Check it: run `astrona submit`. The check `delivered` passes.

## Step 3: Turn on prune and self-heal

The Application has `automated: {}`. Add the two switches:

```sh
kubectl -n argocd patch application scout-staging --type merge \
  -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

Check it: run `astrona submit`. All three checks pass. The check `enforces-git` scales the Deployment by hand and waits for Argo CD to undo it.

## Why this works

The bad release was a commit, so the repair is a commit. A revert keeps the record of both the release and the repair, and Argo CD delivers it like any other change. Self-heal and prune make Git the only way to change the staging objects: a hand edit is reverted, and an object that is removed from Git is removed from the cluster.
