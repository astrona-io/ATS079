---
draft: true
exam_objectives:
- Incident Response in Platform Engineering
---
# Incident Roles, Evidence And Platform Recovery

This module explains how a platform team responds when a service on the cluster stops working. It covers who does what during an incident, which evidence Kubernetes keeps about a failure, how to restore service by rolling back a bad release, and how to tell the main classes of pod failure apart. Every technique is shown on a kind cluster, with plain `kubectl` and no extra tools.

## Learning Goals

- Distinguish the incident roles and explain why mitigation comes before root cause analysis.
- Read the evidence that Kubernetes records: Deployment conditions, ReplicaSets, events and pod states.
- Explain how a rolling update keeps the old pods running, and how `kubectl rollout undo` restores a working revision.
- Tell an image pull failure, a configuration error, a crash loop and a failing readiness probe apart.
- Record an incident timeline and its follow-up actions in a form that others can read later.

## Before You Start

You should know what a pod, a Deployment and a namespace are. The hands-on part uses a playground with a kind cluster and `kubectl`. Technical terms are defined where they first appear.

## Reading Order

1. Incident Roles, Severity And Evidence
2. Mitigation First: Rolling Back A Bad Release
3. Configuration Faults, Crash Loops And Readiness
4. Summary

<!-- astrona:playground -->
