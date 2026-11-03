---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Deployment Strategies And Progressive Delivery

This module explains how continuous delivery puts a new version of an application in front of users. A deployment strategy is the rule for replacing the old version with the new one: how many copies change at a time, whether both versions run together and how fast the team can go back. The module uses plain Kubernetes Deployments and Services, so every step is visible with `kubectl`.

## Learning Goals

- Compare the recreate and rolling update strategies and set `maxSurge` and `maxUnavailable`.
- Explain blue/green delivery and switch traffic by changing a Service selector.
- Explain canary delivery, a traffic share by replica ratio and the tools that give finer control.
- Verify a rollout with status and endpoints, and go back with the revision history.

## Before You Start

You should know what a pod, a Deployment and a Service are. The hands-on parts use a playground with a kind cluster and `kubectl`. Technical terms are defined where they first appear.

## Reading Order

1. Recreate And Rolling Update
2. Blue/Green With A Service Selector
3. Canary Delivery And Progressive Tools
4. Verifying And Reversing A Release
5. Summary

<!-- astrona:playground -->
