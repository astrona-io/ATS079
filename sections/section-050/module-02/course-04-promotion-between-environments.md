---
draft: true
exam_objectives:
- GitOps for Application Environments
---
# Promotion Between Environments

**Promotion** is the move of a tested version from one environment to the next, for example from staging to production. In GitOps a promotion is a change in Git. This part compares the common ways to arrange it and shows what makes a promotion safe.

## What moves

Three things can move between environments: an image tag, a chart version and a set of settings. Keep them separate. The tag changes often, the settings change rarely, and mixing them in one commit makes a promotion hard to review.

## Promotion by folder

Each environment has a folder with an overlay, as in `overlays/staging` and `overlays/production`. A promotion edits the tag in the folder of the next environment. The history of `overlays/production` is then the history of production. Folders are visible in one branch, so a reviewer sees the differences with a plain `diff`.

## Promotion by branch

Each environment has a branch, and a promotion is a merge from the staging branch to the production branch. The strength is a clear gate: a pull request to the production branch. The weakness is drift. Branches that are not merged often differ in more than the version, and a merge can pull in unwanted changes. Folders are easier to keep honest, so they are the more common choice.

## Promotion by pull request

In both layouts, a promotion can be a pull request that the pipeline opens after staging is healthy. A person or a policy approves it, and the merge is the release. The pull request records who approved and when.

## A gated promotion

A safe promotion has a gate between two environments:

1. The change is merged into the staging folder.
2. Argo CD delivers it, and tests or a post-sync hook run against staging.
3. When the checks pass, the pipeline opens the change for production.
4. A person approves, or a rule allows it, and the merge delivers it.

```mermaid
flowchart LR
    S["Staging commit"] --> D["Argo CD delivers"]
    D --> T{"Checks pass?"}
    T -- yes --> P["Production pull request"]
    T -- no --> X["Stop and fix"]
    P --> M["Approve and merge"]
```

The diagram shows the gate: production changes only after staging has proven the same version.

## Order inside an ApplicationSet

An ApplicationSet can also order the rollout of its Applications with **progressive syncs**. The strategy `RollingSync` updates steps of Applications in order and waits for each step to be healthy before it starts the next. A step selects Applications by label. This feature is behind a flag in the controller, so check that it is on before you rely on it.

## Promote in the playground

<!-- astrona:playground:renew -->
With the `scout-envs` ApplicationSet from the previous part running, change the tag in staging only. In your clone of the repository:

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
sed -i.bak 's/newTag: 6.14.0/newTag: 6.15.0/' overlays/staging/kustomization.yaml && rm overlays/staging/kustomization.yaml.bak
git -c user.name=ci -c user.email=ci@starfleet.local commit -am "promote scout to 6.15.0 in staging"
git push origin main
```

Ask Argo CD to refresh, then compare the image in both environments:

```sh
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-staging get deploy scout -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl -n starfleet-production get deploy scout -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Staging shows 6.15.0 and production still shows 6.14.0. Repeat the edit for `overlays/production` as a second commit to promote.

## Common pitfalls

> [!WARNING]
> A promotion that changes the staging and production folders in one commit has no gate. Branches that drift apart make a merge risky. Automatic promotion without a health check promotes a broken version. A moving tag such as `latest` makes a promotion meaningless, because the same tag can point to different images.
