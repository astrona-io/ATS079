---
draft: true
exam_objectives:
  - GitOps for Application Environments
---
# Section 050: GitOps for Application Environments

This section explains how Argo CD describes one environment and keeps many environments apart: the Application with its source and destination, the project that limits it, the deletion lifecycle of its objects, and the ApplicationSet that generates many Applications from one template. Everything runs on a kind cluster with an in-cluster Git server and Argo CD.

**Exam objective covered:** GitOps for Application Environments

---

## What You Will Master

- Describe the source and the destination of an Application and pin it to a commit.
- Explain how an AppProject limits repositories, destinations and kinds, and read the refusal.
- Explain the tracking annotation and the effect of the cascade finalizer on deletion.
- Generate Applications from a list with an ApplicationSet and explain what adding and removing an element does.
- Promote a version through generated environments by commit and retire an environment safely.

---

## The Learning Path

### 1. Application Source, Destination And Project Boundaries
*   **Module Reader:** **[Module 1: Application Source, Destination And Project Boundaries](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-050/module-01/playground` - kind cluster, Gitea, Argo CD 3.5.4. Repository credentials only, no project and no Application; no task.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-050/module-01/playground
    ```
*   **Lab:** `sections/section-050/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-050/module-01/labs/lab-01
    astrona submit -c .
    ```

### Section Capstone Challenge
*   **Comprehensive Challenge:** Environment Generation Capstone - `sections/section-050/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-050/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Generate staging, production and preview from one ApplicationSet, promote staging and production in two commits and retire preview by removing its element.

### Knowledge Check
*   **Quiz:** 11 questions in `sections/section-050/quiz.yaml`. The pass score is 70 percent.
