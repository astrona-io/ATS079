---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Canary Delivery And Progressive Tools

Blue/green moves all users at once. If the new version has a defect that tests missed, every user meets it. A canary delivery sends the new version to a small share of the traffic first, measures the result and widens the share only when the measurements look good.

This part builds a canary with plain Kubernetes objects, shows the limits of that approach and names the tools that give precise control.

## The idea

In a canary delivery, the canary is a small group of pods that run the new version. The team watches their error rate and latency against the old version. If the canary is healthy, the team increases its share until it serves everything. If not, the team removes the canary and only a small share of the users saw the problem.

## A canary by replica ratio

A Service spreads requests over all ready pods that match its selector. If the stable and canary pods share a label, the share of traffic follows the share of pods. Nine stable pods and one canary pod give the canary about one tenth of the connections.

Both Deployments need the label that the Service selects, `app: scout`, and a second label that tells them apart.

<!-- astrona:playground:renew -->
The playground Deployment `scout` also carries the label `app: scout`, so the Service would send requests to it as well. Scale it to zero so that only the two tracks below take traffic:

```sh
kubectl -n starfleet scale deploy/scout --replicas=0
```

Save this as `deployment-scout-stable.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scout-stable
  namespace: starfleet
spec:
  replicas: 3
  selector:
    matchLabels:
      app: scout
      track: stable
  template:
    metadata:
      labels:
        app: scout
        track: stable
    spec:
      containers:
        - name: scout
          image: ghcr.io/stefanprodan/podinfo:6.14.0
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
kubectl apply -f deployment-scout-stable.yaml
```

Save this as `deployment-scout-canary.yaml`. It runs one pod of the new version:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scout-canary
  namespace: starfleet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scout
      track: canary
  template:
    metadata:
      labels:
        app: scout
        track: canary
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
kubectl apply -f deployment-scout-canary.yaml
```

The Service `scout` of the playground selects `app: scout` and therefore matches all four pods of the two tracks. Send 20 requests from the client pod and count the versions:

```sh
kubectl -n starfleet exec deploy/shuttle -- sh -c 'for i in $(seq 1 20); do curl -s --max-time 5 http://scout/ | grep "\"version\""; done' | sort | uniq -c
```

The counts show both versions. The canary version appears in about a quarter of the answers, but the exact numbers vary, because the share depends on how connections are spread and not on a fixed rule. If the canary misbehaves, scale it to 0 with `kubectl -n starfleet scale deploy/scout-canary --replicas=0`. To widen the canary, raise its replicas and lower the stable replicas.

## Limits of the replica ratio

The share of traffic can only be a multiple of one pod. One percent needs 100 pods. A request can reach either version, so one user may see the old version and the new version in a row. The pattern has no automatic check: a person must read the metrics and decide.

## Tools for precise control

Controllers add what plain Kubernetes does not have. Argo Rollouts replaces the Deployment with a `Rollout` object. It sets canary steps such as 10 percent, then a pause, then 50 percent, and it can run an analysis that reads metrics and aborts the rollout when they are bad. A service mesh such as Istio or an ingress controller with weighted routes can split traffic by exact percentage or by request header, independent of the pod count. Flagger offers similar automation.

A **feature flag** is a switch in the application that turns a feature on or off at run time. The new code ships to everyone but stays hidden for most users, and the team enables it for a small group first. Flags separate the deployment of code from the release of a feature, and they allow an instant disable without a new deployment.

Progressive delivery is the name for these methods together: release in small steps, measure and decide with data.

## Common pitfalls

> [!WARNING]
> A replica ratio gives only a rough share, not a fixed percentage. A canary needs metrics that separate its results from the stable version, otherwise nobody can judge it. A canary pod that shares the label of the Service starts receiving traffic when it becomes ready, even if the team wanted to test it first. Feature flags left in the code after a release become hidden complexity.
