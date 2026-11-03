---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Repository Layout, Sync Mechanics And Secrets

This module explains how a GitOps repository is organised and how Argo CD turns its content into a running application. It covers the structure of the repository, the order in which Argo CD applies objects, the health checks that decide when a sync is done, and the safe way to keep secrets when the repository is the source of truth.

## Learning Goals

- Describe a GitOps repository layout with a base and per-environment overlays, and render it with Kustomize.
- Order a sync with sync waves and run one-time tasks with sync hooks.
- Read the sync and health status of an Application and use sync options to change how objects are applied.
- Explain why secrets cannot be stored in Git as plain text and name the common solutions.

## Before You Start

You should know what Git, a Deployment and an Argo CD Application are. The hands-on parts use a playground with a kind cluster, Gitea (a Git server), Argo CD and `kubectl`. Technical terms are defined where they first appear.

## Reading Order

1. Repository Layout And Rendering With Kustomize
2. Sync Waves And Hooks
3. Health, Diff And Sync Options
4. Secrets In A GitOps Repository
5. Summary

<!-- astrona:playground -->
