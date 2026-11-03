# Overview: Detection: Signals, Alerts And Service Level Objectives (Playground)

This is a **playground**, not a lab. It starts a cluster with a healthy service and waits. There is no task, no `astrona submit` and no pass or fail. Break the service, repair it, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- The Deployment `scout` in the namespace `starfleet`: two replicas of the `podinfo` image 6.15.0, a readiness probe on `/readyz` and `progressDeadlineSeconds: 60`. A Service `scout` sends traffic to it on port 80.
- `shuttle`, a client pod with `curl`, in the same namespace.
- No ConfigMap `incident-record` and no `probe` Deployment exist yet. The reading creates them.

## Helpers

Paste these once in each new terminal. `unhealthy` lists every pod that is not fully ready, with its restart count. `last_exit_codes` prints the last exit code of the first container of each pod.

```sh
unhealthy() {
  kubectl get pods -A --no-headers | awk '{split($3,r,"/"); if ($4 != "Running" || r[1] != r[2]) print}'
}
last_exit_codes() {
  kubectl -n starfleet get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}{end}'
}
```

Use them like this: `unhealthy`, `last_exit_codes`.

## Practice tasks

- Create a Deployment named `crasher` from `curlimages/curl:8.22.0` with the command `sh -c "exit 3"`. Watch the status change and read the exit code.
- Create a Deployment from `ghcr.io/stefanprodan/podinfo:6.15.0` with a readiness probe on port 9999. Explain why it shows `Running` with `0/1` ready and why the Service has no endpoints.
- Reference an image tag that does not exist and read the `Failed` and `BackOff` events.
- Request 100 CPUs in a pod and read the `FailedScheduling` event.
- Calculate the error budget in minutes for 99.5, 99.9 and 99.99 percent over 30 days.
