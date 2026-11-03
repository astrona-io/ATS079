---
draft: true
exam_objectives:
  - Incident Response in Platform Engineering
---
# Section 020: Incident Response in Platform Engineering

This section teaches the first hour of a platform incident: who does what, which evidence Kubernetes keeps, how to restore service by rolling back a bad release, and how to tell the main classes of pod failure apart. Everything runs on a kind cluster with plain `kubectl`.

**Exam objective covered:** Incident Response in Platform Engineering

---

## What You Will Master

- Name the incident roles and explain why mitigation comes before root cause analysis.
- Read Deployment conditions, ReplicaSets, pod states and events as evidence.
- Explain why a failed rolling update keeps the old pods running, and roll back with `kubectl rollout undo`.
- Classify an image pull failure, a configuration error, a crash loop and a failing readiness probe.
- Write an incident record that others can use in a review.

---

## The Learning Path

### 1. Incident Roles, Evidence And Platform Recovery
*   **Module Reader:** **[Module 1: Incident Roles, Evidence And Platform Recovery](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-020/module-01/playground` - kind cluster, `kubectl`. A healthy `scout` with two replicas runs in `starfleet`; nothing is broken.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/module-01/playground
    ```
*   **Lab:** `sections/section-020/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/module-01/labs/lab-01
    astrona submit -c .
    ```

### 2. Detection: Signals, Alerts And Service Level Objectives
*   **Module Reader:** **[Module 2: Detection: Signals, Alerts And Service Level Objectives](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-020/module-02/playground`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/module-02/playground
    ```
*   **Lab:** `sections/section-020/module-02/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/module-02/labs/lab-01
    astrona submit -c .
    ```
*   **Quiz:** 10 questions in `sections/section-020/module-02/quiz.yaml`.

### Section Capstone Challenge
*   **Comprehensive Challenge:** Incident Response Capstone - `sections/section-020/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Repair three services that fail for three different reasons, without deleting any Deployment, and record the cause of each in a ConfigMap.

### Knowledge Check
*   **Quiz:** 11 questions in `sections/section-020/quiz.yaml`. The pass score is 70 percent.
