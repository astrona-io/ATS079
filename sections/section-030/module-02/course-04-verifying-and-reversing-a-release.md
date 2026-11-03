---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Verifying And Reversing A Release

A delivery is not finished when the command returns. It is finished when the team knows the new version works for users. If it does not, the team needs the fastest safe way back. Both depend on evidence that Kubernetes already keeps.

This part shows how to verify a rollout, how the revision history supports a rollback and how a delivery tool automates the same checks.

## Verify the rollout

The command `kubectl rollout status` waits until a Deployment finished an update. It exits with success when all replicas are updated, ready and available, and with an error when the Deployment misses its progress deadline.

<!-- astrona:playground:renew -->
Update the image of the Deployment and wait for the result. The playground Deployment `scout` runs 6.15.0 with two replicas. If you scaled it to zero or replaced it in an earlier exercise, run `astrona destroy` and start a fresh playground first.

```sh
kubectl -n starfleet set image deploy/scout scout=ghcr.io/stefanprodan/podinfo:6.14.0
kubectl -n starfleet rollout status deploy/scout --timeout=120s
```

The second command ends with a line that says the rollout completed. The field `progressDeadlineSeconds` of the Deployment sets how long Kubernetes waits for progress before it marks the rollout as failed. The default is 600 seconds.

A finished rollout shows that pods are ready, and not that users are happy. Add checks that look at the service: read the endpoints and send a request to the Service.

```sh
kubectl -n starfleet get endpoints scout
kubectl -n starfleet exec deploy/shuttle -- curl -s --max-time 5 http://scout/ | grep '"version"'
```

The endpoints must list one address for each ready pod, and the answer must show the expected version. Teams add metric checks on top: error rate and latency compared with the previous version for a few minutes.

## The revision history

A Deployment keeps old ReplicaSets as revisions. The field `revisionHistoryLimit` sets how many it keeps, and the default is 10. List the revisions:

```sh
kubectl -n starfleet rollout history deploy/scout
```

Each revision has a number. The column `CHANGE-CAUSE` shows the text of the annotation `kubernetes.io/change-cause`, which is empty unless someone sets it. Set it after each release so the history says what changed:

```sh
kubectl -n starfleet annotate deploy/scout kubernetes.io/change-cause="release scout 6.14.0" --overwrite
```

## Go back

The command `kubectl rollout undo` makes the Deployment use the previous revision again:

```sh
kubectl -n starfleet rollout undo deploy/scout
kubectl -n starfleet rollout status deploy/scout --timeout=120s
```

The rollback is itself a rollout. It follows the same strategy fields, so it is safe and gradual. With `--to-revision=<number>` the command goes back to a chosen revision. A rollback only changes the pod template. Data changes and configuration in other objects do not go back.

For blue/green, the rollback is the selector patch in the other direction. For a canary, it is scaling the canary to zero.

## Roll back or roll forward

When a release is bad, the fastest recovery is to restore the last known good version. Fixing the defect and releasing again takes longer and adds risk during an incident. Roll forward only when the fix is tiny and a rollback is impossible, for example after an irreversible data migration.

## Automating the decision

A delivery tool such as Argo CD reports the health of what it delivered: for a Deployment, health is `Healthy` when the rollout is complete and `Degraded` or `Progressing` otherwise. A progressive delivery controller goes further and reads metrics. It moves to the next step only when the analysis passes and goes back on its own when it fails. The principle is the same as the manual one: a defined check, a defined threshold and a defined action.

The evidence of a release, who changed what and when, goes into the delivery record, which lets a reviewer answer "what ran in production at that time".

## Common pitfalls

> [!WARNING]
> `rollout status` shows pod readiness, not user experience, so add a service check. An empty `CHANGE-CAUSE` makes the history hard to read. A rollback does not undo database changes or other objects. `revisionHistoryLimit: 0` removes the ability to roll back.
