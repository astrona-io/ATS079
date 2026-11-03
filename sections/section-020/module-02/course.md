---
draft: true
exam_objectives:
- Incident Response in Platform Engineering
---
# Detection: Signals, Alerts And Service Level Objectives

This module explains how a platform team learns that something is wrong before the users report it. It covers the signals that a Kubernetes platform produces, the rules for turning signals into alerts that a person can act on, and the service level objectives that decide how much failure is acceptable. It ends with the first minutes after an alert, when the team measures how many workloads are affected.

## Learning Goals

- Name the signals of a platform (metrics, logs, events and traces) and read events, logs and pod status with `kubectl`.
- Explain why alerts should describe symptoms that users feel, and what makes an alert actionable.
- Define a service level indicator, a service level objective and an error budget, and calculate a budget in minutes.
- Scope an incident from the first alert by listing which workloads fail and how.

## Before You Start

You should know what a pod, a Deployment and a namespace are. The hands-on parts use a playground with a kind cluster and `kubectl`. Technical terms are defined where they first appear.

## Reading Order

1. Signals: Metrics, Logs, Events And Traces
2. Symptoms, Causes And Actionable Alerts
3. Indicators, Objectives And Error Budgets
4. Scoping An Incident From The First Alert
5. Summary

<!-- astrona:playground -->
