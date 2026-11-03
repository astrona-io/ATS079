---
draft: true
exam_objectives:
  - GitOps Basics and Workflows
---
# Section 040: GitOps Basics and Workflows

This section explains what a GitOps setup is made of and where its limits are: the principles, the agent and its runtime, the reconciliation loop with its self-heal and prune switches, and the policy that limits what the agent may do. Everything runs on a kind cluster with an in-cluster Git server and Argo CD.

**Exam objective covered:** GitOps Basics and Workflows

---

## What You Will Master

- State the four GitOps principles and map them to the components of an Argo CD setup.
- Explain the management scope of the agent and the bootstrap dependency.
- Describe what the reconciliation loop compares and what automated, selfHeal and prune each change.
- Explain how an AppProject limits sources, destinations and kinds, and read an InvalidSpecError condition.
- Explain how identity and ownership are recorded, and undo a bad release with a revert commit.

---

## The Learning Path

### 1. Managed Runtimes, Agents And Policy Boundaries
*   **Module Reader:** **[Module 1: Managed Runtimes, Agents And Policy Boundaries](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-040/module-01/playground` - kind cluster, Gitea, Argo CD 3.5.4. A staging Application with `automated: {}`; no task.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-040/module-01/playground
    ```
*   **Lab:** `sections/section-040/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-040/module-01/labs/lab-01
    astrona submit -c .
    ```

### Section Capstone Challenge
*   **Comprehensive Challenge:** Policy Boundary Capstone - `sections/section-040/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-040/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Create a project that allows only staging, move the staging Application into it and show that an Application for production is refused.

### Knowledge Check
*   **Quiz:** 11 questions in `sections/section-040/quiz.yaml`. The pass score is 70 percent.
