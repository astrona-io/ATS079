---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# DAG Dependencies, Conditional Tasks And Parallel Work

This module explains how a continuous integration (CI) pipeline decides which task runs when. A CI pipeline builds and checks every change to the source code, and it produces an artifact that a later stage can deliver. The module uses Argo Workflows, a Kubernetes workflow engine, because its Directed Acyclic Graph (DAG) template shows the ordering rules in plain YAML.

## Learning Goals

- Explain acyclic task dependencies and which tasks the controller may run in parallel.
- Distinguish a data reference from a scheduling dependency, and write a `depends` expression with task results.
- Interpret task phases, conditional tasks, fail-fast behavior and retries.
- Limit concurrency with parallelism settings and read the timing of each task from the workflow status.

## Before You Start

You should know what a pod and a namespace are. The hands-on part uses a playground with a kind cluster, Argo Workflows and `kubectl`. Technical terms are defined where they first appear.

## Reading Order

1. DAG Dependencies, Conditional Tasks And Parallel Work
2. Conditional Tasks, Failure And Retries
3. Data, Outputs And Parallelism Limits
4. Summary

<!-- astrona:playground -->
