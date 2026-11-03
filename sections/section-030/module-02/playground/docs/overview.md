# Overview: Deployment Strategies And Progressive Delivery (Playground)

This is a **playground**, not a lab. It starts a cluster with a healthy service and waits. There is no task, no `astrona submit` and no pass or fail. Break the service, repair it, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- The Deployment `scout` in the namespace `starfleet`: two replicas of the `podinfo` image 6.15.0, a readiness probe on `/readyz` and `progressDeadlineSeconds: 60`. A Service `scout` sends traffic to it on port 80.
- `shuttle`, a client pod with `curl`, in the same namespace.
- No blue, green, stable or canary Deployment exists yet. The reading creates them.

## Helpers

Paste these once in each new terminal. `versions` sends 20 requests from `shuttle` to the Service and counts the answers by version. `where` prints the pods that the Service sends traffic to.

```sh
versions() {
  kubectl -n starfleet exec deploy/shuttle -- sh -c 'for i in $(seq 1 20); do curl -s --max-time 5 http://scout/ | grep "\"version\""; done' | sort | uniq -c
}
where() {
  kubectl -n starfleet get endpoints scout
  kubectl -n starfleet get pods -l app=scout -o wide
}
```

Use them like this: `versions`, `where`.

## Practice tasks

- Set the strategy of `scout` to `Recreate`, change the image and watch the pods with `kubectl -n starfleet get pods -w`. Write down the time with no ready pod.
- Set `maxSurge: 0` and `maxUnavailable: 1`, change the image and count the pods during the update.
- Build the blue and green Deployments, switch the Service selector to green and back, and run `versions` after each switch.
- Build a stable and a canary Deployment with 3 and 1 replicas. Run `versions` and change the ratio.
- Release a bad image tag with `rollout status`, read the failure after the progress deadline and go back with `rollout undo`.
