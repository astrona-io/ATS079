---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Managed Runtimes, Agents And Policy Boundaries

This module explains what a GitOps setup is made of and where its limits are. A Git repository holds the desired state. An agent, here Argo CD, reads it and reconciles a runtime, here a Kubernetes cluster, so that the running objects match. A policy decides what the agent may read and where it may write. The module follows these pieces from the four principles of GitOps to a concrete refusal: an Application that tries to deliver to a namespace that its project does not allow.

The tools are Git, Argo CD and `kubectl`. A kind cluster is the runtime, and a Git server inside the cluster is the store.

## Learning Goals

- State the four GitOps principles and map each one to a component of an Argo CD setup.
- Explain the management scope of the agent and what has to exist before it can manage anything.
- Describe what the reconciliation loop compares and what `automated`, `selfHeal` and `prune` each change.
- Explain how an AppProject limits sources, destinations and kinds, and read an `InvalidSpecError` condition.
- Explain who the cluster sees as the author of a change and how ownership of an object is recorded.
- Undo a bad release by a revert commit that keeps the history.

## Before You Start

You should know what a Deployment, a namespace and a Git commit are. The hands-on part uses a playground with a kind cluster, Argo CD and a Git server inside the cluster. Technical terms are defined where they first appear.

## Reading Order

1. GitOps Principles And The Components That Implement Them
2. Reconciliation: Drift, Self-Heal And Prune
3. Policy Boundaries: Identity, Ownership And Rollback
4. Summary

<!-- astrona:playground -->
