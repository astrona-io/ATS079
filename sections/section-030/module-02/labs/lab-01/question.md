# Question

Solve this question on: `terminal`

The platform team delivers `scout` with the blue/green pattern in the namespace `starfleet`. The Deployment `scout-blue` runs version 6.14.0 and receives all traffic through the Service `scout`. The Deployment `scout-green` runs version 6.15.0, is ready and receives no traffic. The release is approved.

1. Change the update strategy of `scout-blue` to a rolling update with `maxSurge` 1 and `maxUnavailable` 0, so that a later hotfix of the old environment keeps all pods ready during the update.
2. Switch the traffic to green by changing the selector of the Service `scout`. Do not change any Deployment image and do not delete a Deployment.
3. Keep `scout-blue` running with two ready replicas, so that a rollback is possible.
4. Create the ConfigMap `release-record` in the namespace `starfleet` with these keys:
   - `strategy`: exactly `blue-green`.
   - `live`: exactly `green`.
   - `previous`: exactly `blue`.
   - `rollback`: the one `kubectl` command that would switch the traffic back to blue.

When you finish, these must be true:

- The Service `scout` selects `version: green`, its two endpoints are the green pods and a request returns version 6.15.0.
- `scout-blue` has two ready replicas and the strategy above.
- The ConfigMap `release-record` has the keys above.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
