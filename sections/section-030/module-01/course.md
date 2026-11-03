---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Build Artifacts, Notifications And Observable Delivery Contracts

This module explains how continuous integration (CI) and continuous delivery (CD) fit together, and what each side must promise to the other. CI produces an artifact that has been checked. CD takes that artifact to an environment. The agreement between them, which is called the delivery contract in this module, is small: a reference to an immutable artifact and a change in Git that names it. Everything else is observation. The module follows one change from a commit to a running pod, and shows which signals can be trusted and which cannot.

The tools are Git, Argo CD and `kubectl`. Git is the place where the contract is written, Argo CD reads it, and a kind cluster is the environment.

## Learning Goals

- Distinguish continuous integration, continuous delivery and continuous deployment, and name the artifact that connects them.
- Explain why CI writes to Git and does not hold credentials for the cluster, and why that limits the authority of each side.
- Promote a version by a commit and follow the change through Argo CD to the running pods.
- Read the sync status, the health status and the revision of an Application, and explain why a green pipeline does not prove a delivery.
- Explain the role of notifications and keep a delivery record that links a commit to a running version.

## Before You Start

You should know what a Deployment and a namespace are, and you should be able to use `git` on the command line. The hands-on part uses a playground with a kind cluster, Argo CD and a Git server inside the cluster. Technical terms are defined where they first appear.

## Reading Order

1. CI, Continuous Delivery And Continuous Deployment
2. Git As The Handoff: Promotion By Commit
3. Observing Delivery: Status, Revision And Delivery Records
4. Summary

<!-- astrona:playground -->
