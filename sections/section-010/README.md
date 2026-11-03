---
draft: true
exam_objectives:
  - Continuous Integration Pipelines Overview
---
# Section 010: Continuous Integration Pipelines Overview

This section teaches you to read and write a continuous integration (CI) pipeline as a graph of tasks. You will describe the order of the tasks with dependencies, decide what happens after a failure, pass data between tasks and limit how many tasks run at once. The tool is Argo Workflows on a kind cluster.

**Exam objective covered:** Continuous Integration Pipelines Overview

---

## What You Will Master

- Explain acyclic task dependencies and which tasks run in parallel.
- Write a `depends` expression with task results such as `Succeeded`, `Failed` and `Completed`.
- Skip a task with a `when` expression and read the `Skipped` result.
- Explain fail-fast behavior and a retry strategy, and why a retried task must be safe to repeat.
- Pass an output parameter to a later task and keep the reference and the dependency together.
- Limit concurrency with `parallelism` and read the timing of each task from the workflow status.

---

## The Learning Path

### 1. DAG Dependencies, Conditional Tasks And Parallel Work
*   **Module Reader:** **[Module 1: DAG Dependencies, Conditional Tasks And Parallel Work](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-010/module-01/playground` - kind cluster, `jq` on your machine. Argo Workflows is installed in `starfleet`; no workflow exists yet.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-010/module-01/playground
    ```
*   **Lab:** `sections/section-010/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-010/module-01/labs/lab-01
    astrona submit -c .
    ```

### Section Capstone Challenge
*   **Comprehensive Challenge:** CI Pipelines Capstone - `sections/section-010/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-010/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Write a release pipeline with parallel checks, an output that package receives, a retried task, a skipped publish task and a limit of two concurrent pods, and run it twice.

### Knowledge Check
*   **Quiz:** 12 questions in `sections/section-010/quiz.yaml`. The pass score is 70 percent.
