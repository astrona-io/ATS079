---
draft: true
exam_objectives:
  - CI/CD Relationship Fundamentals
---
# Section 030: CI/CD Relationship Fundamentals

This section explains how continuous integration, continuous delivery and continuous deployment relate, what CI hands to CD, and how to tell from Argo CD whether a delivery really happened. Everything runs on a kind cluster with an in-cluster Git server and Argo CD.

**Exam objective covered:** CI/CD Relationship Fundamentals

---

## What You Will Master

- Distinguish continuous integration, continuous delivery and continuous deployment by what each automates.
- Explain why an immutable artifact reference ties the tested bytes to the deployed bytes.
- Compare push delivery and pull delivery and describe the delivery contract between CI and Argo CD.
- Promote a version by commit and roll back by revert, and explain the refresh delay.
- Read sync status, health status, revision and history as separate pieces of evidence.
- Write a delivery record that links an environment, a version and a commit.

---

## The Learning Path

### 1. Build Artifacts, Notifications And Observable Delivery Contracts
*   **Module Reader:** **[Module 1: Build Artifacts, Notifications And Observable Delivery Contracts](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-030/module-01/playground` - kind cluster, Gitea, Argo CD 3.5.4. A delivered staging environment on 6.14.0; no task.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/module-01/playground
    ```
*   **Lab:** `sections/section-030/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/module-01/labs/lab-01
    astrona submit -c .
    ```

### 2. Deployment Strategies And Progressive Delivery
*   **Module Reader:** **[Module 2: Deployment Strategies And Progressive Delivery](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-030/module-02/playground`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/module-02/playground
    ```
*   **Lab:** `sections/section-030/module-02/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/module-02/labs/lab-01
    astrona submit -c .
    ```
*   **Quiz:** 10 questions in `sections/section-030/module-02/quiz.yaml`.

### Section Capstone Challenge
*   **Comprehensive Challenge:** Delivery Contract Capstone - `sections/section-030/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Promote a version through staging and then production in two commits, verify both deliveries at the head commit, and record which commit changed which environment.

### Knowledge Check
*   **Quiz:** 11 questions in `sections/section-030/quiz.yaml`. The pass score is 70 percent.
