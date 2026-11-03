---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# Summary

A CI pipeline is a set of tasks with ordering rules. In a DAG, each task lists the tasks it depends on, and the workflow controller starts a task only when those conditions hold. Because no dependency path returns to its starting task, the graph always has a valid forward order. Tasks that do not depend on each other become eligible at the same time, and the controller creates a pod for each of them.

A dependency is a condition on a result, not only on a name. A task can wait for a success, a failure, a skip or any completion of an earlier task. A `when` expression decides whether an eligible task runs at all, and a skipped task has its own result that later conditions can test. The default condition, a bare task name, means success or skip. Cleanup and notification tasks use a wider condition on purpose.

Failure handling is a scheduling decision. With fail-fast on, the controller stops creating new pods after the first failure, but it does not stop pods that already run and it does not undo their side effects. A retry strategy runs the same task again in a new pod, so a task that can run twice needs to be safe to repeat. A task that passes data on must produce the output, and a consumer that references an output must also depend on its producer.

Concurrency has limits that the graph does not show. A parallelism setting on the workflow or on one DAG caps the number of pods that run at once, and the cluster can still delay a pod that is ready. The workflow status records the phase, start time and finish time of each task, which is the evidence for what ran in parallel, what waited and which task failed first.

Key facts:

- Acyclic means no dependency path returns to its starting task.
- `depends` can combine results with `&&`, `||` and `!`.
- A DAG cannot mix `depends` and `dependencies` in one task.
- Fail-fast stops new tasks, not running ones, and never rolls back effects.
- A retry is a new pod, so repeated work must be safe.

<!-- astrona:playground:destroy -->
