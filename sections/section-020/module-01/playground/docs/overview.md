# Overview: Incident Roles, Evidence And Platform Recovery (Playground)

This is a **playground**, not a lab. It starts a cluster with a healthy service and waits. There is no task, no `astrona submit` and no pass or fail. Break the service, repair it, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- The Deployment `scout` in the namespace `starfleet`: two replicas of the `podinfo` image 6.15.0, a readiness probe on `/readyz` and `progressDeadlineSeconds: 60`. A Service `scout` sends traffic to it on port 80.
- `shuttle`, a client pod with `curl`, in the same namespace.
- No ConfigMap `incident-record` and no `probe` Deployment exist yet. The reading creates them.

## Helpers

Paste these once in each new terminal. `evidence` prints the Deployment, ReplicaSets, pods and the most recent events in the order that an incident review reads them. `ask_scout` sends one request from `shuttle` to the Service and prints the version.

```sh
evidence() {
  kubectl -n starfleet get deploy,rs,pods
  kubectl -n starfleet get events --sort-by=.lastTimestamp | tail -n 12
}
ask_scout() {
  kubectl -n starfleet exec deploy/shuttle -- curl -s --max-time 5 http://scout/ | grep '"version"'
}
```

Use them like this: `evidence`, `ask_scout`.

## Practice tasks

- Release the image tag `6.15.99`, run `ask_scout` in a loop while the rollout is stuck and explain why the answers keep coming.
- Set `maxUnavailable: 1` and `maxSurge: 0` in the strategy of `scout`, release the bad tag again and count how many ready pods remain. Explain the difference from the default.
- Make a container exit by giving it the command `sh -c "exit 1"` in a copy of the `shuttle` Deployment, and read the previous logs with `kubectl logs --previous`.
- Reference a Secret that does not exist from an environment variable and read the event. Compare it with a missing ConfigMap key.
- Raise `progressDeadlineSeconds` to 600, release a bad tag and write down how long it takes before the Deployment reports the failure.
