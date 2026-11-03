# Solution

The task has two parts: restore the service from the history of the Deployment, and write the record. The cluster keeps the old ReplicaSet of the Deployment, so the fastest safe action is a rollback.

## Step 1: read the evidence

Start with the Deployment and go down to the events, as in an incident. The rollout is stuck because the new pod cannot start:

```sh
kubectl -n starfleet get deploy,rs,pods
kubectl -n starfleet get events --field-selector reason=Failed --sort-by=.lastTimestamp
```

The new ReplicaSet has a pod in `ImagePullBackOff` or `ErrImagePull`. The event says that the image `ghcr.io/stefanprodan/podinfo:6.15.99` could not be pulled, so the tag does not exist. The old ReplicaSet still has two ready pods, which is why the Service still answers.

## Step 2: roll back

Read the revisions, then write the previous pod template back:

```sh
kubectl -n starfleet rollout history deploy/scout
kubectl -n starfleet rollout undo deploy/scout
kubectl -n starfleet rollout status deploy/scout --timeout=120s
```

`rollout undo` scales the ReplicaSet with the working template up again and scales the failing one down to zero. The failing ReplicaSet is kept, with no replicas, as part of the history.

Check the result:

```sh
kubectl -n starfleet get deploy scout -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=scout
```

The image is `ghcr.io/stefanprodan/podinfo:6.15.0` and the EndpointSlice has two ready addresses.

## Step 3: save the incident record

The record keeps the facts of the incident in one object. The key `cause` names the tag, and `mitigation` and `status` use the exact words that the grader reads.

Save this as `incident-record.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: incident-record
  namespace: starfleet
data:
  severity: "2"
  cause: "The release set the image tag 6.15.99, which does not exist, so the new pod could not pull its image."
  mitigation: rollback
  status: resolved
  timeline: |
    rollout of scout stalled with ImagePullBackOff, old pods kept serving
    rolled back with kubectl rollout undo, 2 of 2 replicas ready on 6.15.0
```

Apply it:

```sh
kubectl apply -f incident-record.yaml
```

Check it:

```sh
kubectl -n starfleet get configmap incident-record -o yaml
```

## Common mistakes

- Setting the image back with `kubectl set image` works, but deleting the Deployment and creating it again removes the history, and the grader rejects it.
- Scaling the Deployment to change the number of pods does not fix a bad image.
- Writing `rolled back` or `Resolved` in the record. The grader reads the exact words `rollback` and `resolved`.
