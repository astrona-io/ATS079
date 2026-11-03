---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# Stages, Shared Workspaces And Image Identity

This module explains what a continuous integration (CI) pipeline produces and how it keeps that product trustworthy. A pipeline moves through stages such as build, test and package. The stages share files, and the last stage names an artifact: the versioned result that a later delivery step deploys. The module uses Argo Workflows on Kubernetes to show each idea in YAML.

## Learning Goals

- Describe the stages of a CI pipeline and the job of each stage.
- Share files between tasks with a workspace volume and pass small values with output parameters.
- Explain why an image tag can change and why an image digest cannot.
- Name the practices that make a build repeatable: pinned inputs, cached dependencies and one build per commit.

## Before You Start

You should know what a pod and a namespace are, and how a DAG orders tasks. The hands-on parts use a playground with a kind cluster, Argo Workflows and `kubectl`. Technical terms are defined where they first appear.

## Reading Order

1. Pipeline Stages And What Each One Proves
2. Sharing Files Between Tasks With A Workspace
3. Image Tags, Digests And Artifact Identity
4. Repeatable Builds, Caching And Pinned Inputs
5. Summary

<!-- astrona:playground -->
