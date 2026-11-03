---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Observing Delivery: Status, Revision And Delivery Records

A delivery has finished only when the environment runs the intended version and is healthy. Several signals claim success earlier than that: the pipeline is green, the push was accepted, a notification arrived. This part lists the signals that Argo CD provides, explains what each one proves, and shows a case in which two of them disagree. It ends with a delivery record, a small object that links a Git commit to a running version.

## The fields of an Application that carry evidence

An Application reports its state in `status`. Four fields matter for delivery.

- `status.sync.status` says whether the live objects match the manifests rendered from Git. The values are `Synced`, `OutOfSync` and `Unknown`.
- `status.sync.revision` is the Git commit that the comparison used. It is the answer to the question which commit was compared.
- `status.health.status` summarises the health of the objects: `Healthy`, `Progressing`, `Degraded`, `Suspended`, `Missing` or `Unknown`. Argo CD computes the health of a Deployment from its status, so a rollout that has not finished is `Progressing`, and a rollout that exceeded its progress deadline is `Degraded`.
- `status.operationState` describes the last sync operation: its phase (`Running`, `Succeeded`, `Failed`, `Error`), the revision that it synced and when it finished.

`status.history` lists the successful syncs with an `id`, a `revision` and a `deployedAt` time.

## Sync and health answer different questions

Sync status asks whether the cluster matches Git. Health asks whether the objects work. They are independent. A bad image tag in Git is applied exactly as written, so the Application is `Synced`, and the Deployment cannot start its new pod, so the Application is `Progressing` and later `Degraded`. The sync operation itself is `Succeeded`, because the objects were applied. A pipeline that watches only the sync status would report a successful delivery of a broken release.

```mermaid
flowchart TB
    G["Git revision"] -->|"sync status: does live match Git?"| L["Live objects"]
    L -->|"health status: do the objects work?"| P["Running pods"]
```

The two arrows are separate checks on separate links. A delivery contract that says success must say which of them it means.

## Signals that look like success

- **A green CI run.** It proves that the artifact was built and that the Git push was accepted. It does not prove that the cluster changed.
- **`Synced` right after a push.** Until the next refresh, Argo CD compares the old revision. The check `Synced` is correct for the revision it knows, and the new commit is not known yet. Compare `status.sync.revision` with the commit that you pushed.
- **A succeeded sync operation.** The objects were applied. The pods may not run.
- **`Healthy` with the wrong version.** If a tag was moved to another image, everything is healthy and the version is not the one that was tested. Only an immutable reference closes this gap.
- **A notification.** The notifications controller of Argo CD watches Applications and sends a message when a trigger fires, for example when a sync succeeds or when the health turns `Degraded`. A message is a prompt for a person and a pointer to the Application. It can arrive late or be lost, and it says nothing that the Application does not say better, so it is not the source of truth.

An automated sync also has a rule about failure: it does not start the same sync again for a commit and parameters whose last attempt failed. A new commit makes a new attempt. A retry in CI that pushes the same content therefore will not start the sync again by itself.

<!-- astrona:playground:renew -->
## Try it: a delivery where sync and health disagree

In the playground, staging runs 6.14.0. Clone the repository, which is reachable from your machine on port 3000, and then release a tag that does not exist.

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
```

Save this as `overlays/staging/kustomization.yaml`:

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
    newTag: 6.15.99
replicas:
  - name: scout
    count: 1
patches:
  - path: message.yaml
```

Commit it, push it and ask for a refresh:

```sh
git add overlays/staging/kustomization.yaml
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "bump scout staging to 6.15.99"
git push origin main
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
```

Check it. Read the three fields of the Application a few times over about a minute and a half:

```sh
kubectl -n argocd get application scout-staging -o jsonpath='{.status.sync.status} {.status.health.status} {.status.operationState.phase}{"\n"}'
```

The sync status is `Synced` and the operation phase is `Succeeded`. The health status is `Progressing` at first and `Degraded` after the 60 second progress deadline of the Deployment. Look at the pods to see why:

```sh
kubectl -n starfleet-staging get pods
```

The new pod is in `ImagePullBackOff`, and the old pod keeps serving. The delivery contract of this change was met in the sense of Git and sync, and it was not met in the sense of health. A pipeline that gates on health would have stopped here.

Now repair the delivery in Git, which is where the desired state lives:

```sh
git revert --no-edit HEAD
git push origin main
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-staging rollout status deploy/scout --timeout=180s
```

The revert is a new commit, so the history keeps both the failed release and the repair. Argo CD delivers it like any other change, and the Application returns to `Synced` and `Healthy` on 6.14.0.

## Try it: write a delivery record

A delivery record links four facts: which environment, which version, which commit and which health at the time. It is written after the delivery has been observed, not before. The command reads the facts from the cluster and from the Application, so nothing is typed by hand:

```sh
kubectl -n starfleet create configmap delivery-record \
  --from-literal=environment=staging \
  --from-literal=version="$(kubectl -n starfleet-staging get deploy scout -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d: -f2)" \
  --from-literal=commit="$(kubectl -n argocd get application scout-staging -o jsonpath='{.status.sync.revision}')" \
  --from-literal=health="$(kubectl -n argocd get application scout-staging -o jsonpath='{.status.health.status}')"
kubectl -n starfleet get configmap delivery-record -o yaml
```

The ConfigMap shows `version: 6.14.0`, the full commit ID of the revert commit and `health: Healthy`. Anyone who reads it later can open the repository at that commit and see the exact desired state that was delivered.

## What a good delivery contract states

A contract that can be checked says four things: the artifact reference (immutable if possible), the Git change that carries it, the signal that means done (sync and health at the commit of the change), and the record of the outcome. This part showed that each of these is a field that can be read, and that the green marker of a pipeline is only the first of them.

## Common pitfalls

> [!WARNING]
> A delivery that is `Synced` can still be `Degraded`, so gate on both and on the revision. A `Synced` read right after a push may refer to the previous commit. A notification is a prompt to look at the Application, not proof that the delivery worked.
