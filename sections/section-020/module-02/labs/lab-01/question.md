# Question

Solve this question on: `terminal`

An alert reports that the namespace `starfleet` has unhealthy workloads. Three Deployments run there: `scout`, `probe` and `beacon`. You are the first responder. Your job in this task is to find the signals and write the detection record. Do not repair, scale, restart or delete anything.

1. Find out which workload is in a crash loop, which workload runs but is not ready, and which workload is healthy. Read the pod status and the events.
2. Read the exit code of the container that keeps stopping.
3. The objective of `scout` is 99.9 percent of requests succeeding over 30 days. Calculate the error budget in minutes of full downtime.

Create the ConfigMap `detection-record` in the namespace `starfleet` with these keys:

- `crashing`: the name of the Deployment in the crash loop.
- `exit-code`: the exit code of its container.
- `not-ready`: the name of the Deployment whose pod runs but is not ready.
- `healthy`: the name of the healthy Deployment.
- `error-budget-minutes`: the budget for the objective above, with one decimal.
- `severity`: any non-empty value, for example `3`.
- `signal`: one sentence that says which signal told you the cause of the crash loop.

When you finish, these must be true:

- The ConfigMap `detection-record` has the keys above with correct values.
- The Deployments `scout`, `probe` and `beacon` still exist and were not changed.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
