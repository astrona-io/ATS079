---
draft: true
exam_objectives:
- GitOps for Application Environments
---
# Application Source, Destination And Project Boundaries

This module explains how Argo CD describes one environment and how many environments are kept apart. An Application names a source, which is a path in a Git repository at a revision, and a destination, which is a cluster and a namespace. An AppProject limits which sources and destinations a group of Applications may use. An ApplicationSet generates many Applications from one template. The module follows an environment from a hand-written Application to a generated one, and shows what happens to its objects when it is deleted.

The tools are Git, Argo CD and `kubectl`. A kind cluster is the runtime, and a Git server inside the cluster is the store.

## Learning Goals

- Describe the source and the destination of an Application and what each field selects.
- Pin an Application to a commit and explain why it then ignores new commits on the branch.
- Explain how an AppProject limits repositories, destinations and kinds, and why an environment belongs in a project.
- Explain the tracking annotation and how an object is tied to the Application that owns it.
- Describe the difference between deleting an Application with and without the cascade finalizer.
- Generate Applications from a list with an ApplicationSet and explain what adding and removing an element does.

## Before You Start

You should know what a Deployment, a namespace and a Git commit are. The hands-on part uses a playground with a kind cluster, Argo CD and a Git server inside the cluster. Technical terms are defined where they first appear.

## Reading Order

1. Application Source And Destination
2. Environments, Projects And The Deletion Lifecycle
3. ApplicationSets: Generating Environments
4. Summary

<!-- astrona:playground -->
