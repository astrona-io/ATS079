---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Summary

A deployment strategy is the rule for replacing the running version with a new one. The Recreate strategy stops all old pods before it starts new ones and causes downtime, which is acceptable only when two versions must never run together. The RollingUpdate strategy replaces pods in steps. The fields `maxSurge` and `maxUnavailable` set the step size, and a readiness probe decides when a new pod may take over.

Blue/green delivery runs two complete environments. The Service selector decides which one receives traffic, and a single selector change switches all users and also reverses the switch. It needs double capacity during the change and a shared data model that both versions can use.

A canary delivery sends the new version to a small share of the traffic first. Plain Kubernetes can approximate the share with the ratio of pods that match one Service, but only in whole pods. Progressive delivery controllers, service meshes and feature flags give exact percentages, automatic analysis and an instant disable without a new deployment.

A release is verified with rollout status, endpoints and a request to the Service, backed by metrics. The Deployment keeps revisions, and `kubectl rollout undo` returns to a previous one through a normal rollout. A rollback restores the pod template only. When a release is bad, restoring the last known good version is usually faster and safer than a new fix.

Key facts:

- Defaults for the rolling update are 25 percent for both fields.
- Both fields set to 0 are rejected.
- A Service selector can switch traffic without restarting pods.
- The revision history is limited by `revisionHistoryLimit`.
- A rollback does not undo changes outside the pod template.

<!-- astrona:playground:destroy -->
