---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Recreate And Rolling Update

Continuous delivery means that a build that passed the pipeline can reach users at any time. The remaining question is how. Replacing every running copy at once is simple, but users see an outage while the new copies start. Replacing them gradually keeps the service up, but two versions run together for a while.

This part covers the two strategies that a Kubernetes Deployment has built in, and shows the two fields that tune the gradual one.

## What a Deployment does during an update

A Deployment manages ReplicaSets. A ReplicaSet keeps a fixed number of identical pods running. When you change the pod template of a Deployment, for example the image, the Deployment controller creates a new ReplicaSet for the new template and moves the pods from the old ReplicaSet to the new one. The field `spec.strategy.type` decides how.

## Recreate

The strategy `Recreate` stops all old pods first and starts the new pods after that. For a short time no pod serves requests. Use it when two versions must never run together, for example when a new version changes a database schema in a way the old version cannot read. The cost is downtime.

## Rolling update

The strategy `RollingUpdate` is the default. It replaces pods in small steps and keeps the Deployment available, as long as the new pods become ready. Two fields set the step size.

- `maxSurge` is how many pods above the wanted replica count may exist during the update. It is a number or a percentage, and the default is 25 percent.
- `maxUnavailable` is how many pods below the wanted count may be not ready during the update. The default is 25 percent too.

With 4 replicas, the defaults round to 1 surge pod (rounded up) and 1 unavailable pod (rounded down). The controller may then run 5 pods in total and must keep at least 3 ready.

A **readiness probe** is the check that decides when a new pod is ready. The rolling update waits for it before it removes an old pod. Without a readiness probe, Kubernetes treats a started container as ready, so a broken version can replace working pods before it answers a single request.

<!-- astrona:playground:renew -->
Save this as `deployment-scout-rolling.yaml`. It keeps all current pods until a new one is ready, because `maxUnavailable` is 0:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scout
  namespace: starfleet
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: scout
  template:
    metadata:
      labels:
        app: scout
    spec:
      containers:
        - name: scout
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          ports:
            - name: http
              containerPort: 9898
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
          resources:
            requests:
              cpu: 10m
              memory: 32Mi
```

Apply it:

```sh
kubectl apply -f deployment-scout-rolling.yaml
```

Change the image and watch the rollout:

```sh
kubectl -n starfleet set image deploy/scout scout=ghcr.io/stefanprodan/podinfo:6.14.0
kubectl -n starfleet rollout status deploy/scout
```

The status command prints one line for each step and ends when all replicas are updated and available. With `maxSurge: 1` and `maxUnavailable: 0`, the Deployment starts one new pod, waits for it to be ready, and only then stops one old pod. The cost of this setting is one extra pod during the update.

List the ReplicaSets to see the result:

```sh
kubectl -n starfleet get rs -l app=scout
```

The new ReplicaSet has 2 pods, and the old one has 0. The old ReplicaSet stays, so a rollback can use it.

## Choosing the numbers

`maxUnavailable: 0` with `maxSurge: 1` favors availability and needs spare capacity for one pod. `maxUnavailable: 1` with `maxSurge: 0` needs no spare capacity, but the service runs one pod short during the update. A percentage scales with the replica count. The values `0` for both fields are not allowed, because the update could not make progress.

During a rolling update both versions answer requests. The application must handle that: new code must read data written by the old code, and the other way round, for the time of the update.

The next question is what to do when you want the switch to be instant and the old version to stay ready.

## Common pitfalls

> [!WARNING]
> A Deployment without a readiness probe counts a started container as ready, so a broken version can replace healthy pods. Setting both `maxSurge` and `maxUnavailable` to 0 is rejected. Rolling updates run two versions together, so incompatible data changes need a different approach. The strategy `Recreate` causes downtime by design.
