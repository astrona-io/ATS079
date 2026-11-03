# Question

Solve this question on: `terminal`

The platform team runs three services in the namespace `starfleet`: `scout`, `probe` and `bridge`. Each has its own Deployment and its own Service. After a change window, all three are down, and each one is broken in a different way. You are the operations lead. Restore all three services and write the incident record.

Rules for the repair:

- Do not delete any Deployment and do not change the number of replicas.
- Fix the cause of each fault. Do not remove the environment variable of `probe`, and do not remove or weaken the readiness probe of `bridge`.
- The healthy image for `scout` and `bridge` is `ghcr.io/stefanprodan/podinfo:6.15.0`. The application listens on port `9898`.

Then create the ConfigMap `incident-record` in the namespace `starfleet` with these keys:

- `severity`: any non-empty value.
- `status`: exactly `resolved`.
- `scout`: one sentence about the cause for `scout`. It must contain the word `image`.
- `probe`: one sentence about the cause for `probe`. It must contain the word `ConfigMap`.
- `bridge`: one sentence about the cause for `bridge`. It must contain the word `readiness`.
- `timeline`: at least one line with what you saw and in which order you repaired the services.

When you finish, these must be true:

- Each Deployment has one ready replica and each Service has one ready endpoint.
- `scout` and `bridge` were updated in place, so their revision number is at least 2.
- `probe` still reads `MODE` from the key `mode` of the ConfigMap `probe-config`, and that key now exists.
- The readiness probe of `bridge` checks the application port with the path `/readyz`.
- The ConfigMap `incident-record` has the keys above.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
