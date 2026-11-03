---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Reconciliation: Drift, Self-Heal And Prune

Reconciliation is the loop that makes the running system match the desired state. This part shows what the loop compares, which events start it, and what the three settings of an automated sync policy change: `automated`, `selfHeal` and `prune`. Each setting answers a different question about who is allowed to change what, and what is allowed to disappear.

## What the loop compares

For each Application, the controller holds three things.

- The **desired state**: the manifests that the repo-server rendered from the source at a revision.
- The **live state**: the objects as the cluster API returns them. The controller keeps a cache of them, which it updates from a watch, so a change in the cluster becomes known within seconds.
- The **sync status**, which is the result of comparing the two. It is `Synced` when every desired object exists and matches, and `OutOfSync` when an object differs, is missing, or exists live and no longer exists in the desired state.

Fields that the cluster fills in itself, such as `status` and generated IDs, are ignored by the comparison. Fields that other controllers legitimately change can be excluded with `ignoreDifferences`.

## What starts a sync

A comparison runs when the desired state changes (a new commit, found by polling about every three minutes, by a refresh request or by a webhook) and when the live state changes (a watch event). The result is a status. A **sync** is a separate step: it applies the desired objects to the cluster. A sync starts in one of two ways. A person starts it, or the sync policy starts it.

The policy has three switches.

| Setting | Question it answers | Effect when it is off |
| --- | --- | --- |
| `automated` | Does the agent sync without being asked? | A person must start every sync. The Application shows `OutOfSync` until then. |
| `automated.selfHeal` | Does the agent undo changes made in the cluster? | A change in the cluster is reported as `OutOfSync` and stays. |
| `automated.prune` | Does the agent delete objects that are no longer in Git? | The objects stay, and the Application stays `OutOfSync`. |

The block `automated: {}` turns on the first switch only. A new commit is delivered, a hand edit in the cluster is not undone, and a removed file leaves its object behind. This is the least surprising setting for a first rollout, and also the one in which Git and the cluster differ most easily without anyone noticing.

## Why prune is separate

Deleting is irreversible in a way that creating is not. A wrong manifest in Git can be fixed by another commit. A deleted object that held data, such as a PersistentVolumeClaim, is gone. For this reason the delete switch is off by default and has to be turned on on purpose. An object can also be protected one by one with the annotation `argocd.argoproj.io/sync-options: Prune=false`.

## Why self-heal needs care

Self-heal makes Git the only way to change an object. That is the goal, and it has costs. A person who scales a Deployment by hand during an incident will see the change undone in seconds. A second controller that changes the same field, such as a horizontal autoscaler that sets `replicas`, will fight the agent forever, each one overwriting the other. The repair is to leave the field out of Git, or to name it in `ignoreDifferences`.

<!-- astrona:playground:renew -->
## Try it: prune and self-heal

Clone the repository, which is reachable from your machine on port 3000:

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
```

Add a ConfigMap to staging. Save this as `overlays/staging/notes.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-notes
data:
  owner: platform
```

Save this as `overlays/staging/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: starfleet-staging
resources:
  - ../../base
  - notes.yaml
labels:
  - pairs:
      environment: staging
images:
  - name: ghcr.io/stefanprodan/podinfo
    newTag: 6.14.0
replicas:
  - name: scout
    count: 1
patches:
  - path: message.yaml
```

Apply it: commit, push and ask Argo CD to refresh.

```sh
git add overlays/staging
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "add scout-notes to staging"
git push origin main
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
```

Check it: after a few seconds the ConfigMap exists.

```sh
kubectl -n starfleet-staging get configmap scout-notes
```

Now remove the file from the desired state. Save this as `overlays/staging/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: starfleet-staging
resources:
  - ../../base
labels:
  - pairs:
      environment: staging
images:
  - name: ghcr.io/stefanprodan/podinfo
    newTag: 6.14.0
replicas:
  - name: scout
    count: 1
patches:
  - path: message.yaml
```

Apply it: commit, push and refresh.

```sh
git add overlays/staging
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "remove scout-notes from staging"
git push origin main
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
```

Check it: the commit is delivered, and the object is still there, because prune is off. The status is `OutOfSync`:

```sh
kubectl -n starfleet-staging get configmap scout-notes
kubectl -n argocd get application scout-staging -o jsonpath='{.status.sync.status}{"\n"}'
```

Turn on prune and self-heal, and read the result:

```sh
kubectl -n argocd patch application scout-staging --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
kubectl -n starfleet-staging get configmap scout-notes
```

The ConfigMap is deleted within a few seconds, and the status is `Synced`. Now repeat the hand edit from before and watch it being undone:

```sh
kubectl -n starfleet-staging scale deploy/scout --replicas=3
kubectl -n starfleet-staging get deploy scout -w
```

The replica count returns to one without any commit. Stop the watch with Ctrl+C. The same agent now has a different relationship to the cluster: before the patch it reported differences, and after the patch it removes them.

## Common pitfalls

> [!WARNING]
> Turning on `prune` can delete objects, including objects that hold data. Review what the next sync would remove before enabling it, and protect important objects with `Prune=false`. Turning on `selfHeal` makes hand edits during an incident disappear, so a team must agree that the change goes through Git first. A field that another controller sets, such as `replicas` under an autoscaler, needs `ignoreDifferences` or it will be reset in a loop.
