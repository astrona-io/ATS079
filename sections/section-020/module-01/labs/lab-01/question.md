# Question

Solve this question on: `terminal`

The platform team runs the web service `scout` in the namespace `starfleet`. It has two replicas, and a Service named `scout` sends traffic to them. A release a few minutes ago changed the container image, and the rollout has not finished. You are the operations lead of this incident.

Restore the service, then write the incident record.

1. Find out why the rollout is stuck, and restore `scout` to the revision that worked. Use the history that the Deployment keeps. Do not delete the Deployment and do not change the number of replicas.
2. Create the ConfigMap `incident-record` in the namespace `starfleet` with these keys:
   - `severity`: any non-empty value, for example `2`.
   - `cause`: one sentence that names the image tag that caused the incident.
   - `mitigation`: exactly `rollback`.
   - `status`: exactly `resolved`.
   - `timeline`: at least one line that says what was seen and what was done.

When you finish, these must be true:

- The Deployment `scout` runs `ghcr.io/stefanprodan/podinfo:6.15.0` with two ready replicas, the rollout is complete, and the Service has two ready endpoints.
- The Deployment still has its ReplicaSet history, including the ReplicaSet of the bad release, which has no replicas.
- The ConfigMap `incident-record` has the keys above.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
