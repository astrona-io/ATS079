---
draft: true
exam_objectives:
- GitOps for Application Environments
---
# ApplicationSet Generators, Project Policy And Promotion

This module goes deeper into how many environments are generated, limited and moved forward. The first module generated Applications from a fixed list. Here the Git repository itself decides which environments exist, a project limits who may sync and when, and a change moves from one environment to the next in a controlled order.

## Learning Goals

- Name the common ApplicationSet generators and choose one for a given problem.
- Generate one Application per folder with the Git directory generator and exclude a folder.
- Combine generators with the matrix generator.
- Limit a team with project roles, sync windows and orphaned-resource monitoring.
- Compare promotion by folder, by branch and by pull request, and describe a gated promotion.

## Before You Start

You should know what an Application, an AppProject and an ApplicationSet are, as covered in the previous module. The hands-on parts use a playground with a kind cluster, Argo CD and a Git server inside the cluster.

## Reading Order

1. Choosing An ApplicationSet Generator
2. The Git Directory Generator And Combined Generators
3. Project Roles, Sync Windows And Orphaned Resources
4. Promotion Between Environments
5. Summary

<!-- astrona:playground -->
