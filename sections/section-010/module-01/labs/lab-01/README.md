---
estimated_duration: 25m
---

# Lab: Build A CI Pipeline As A DAG

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster has Argo Workflows and no pipeline. The learner writes a `WorkflowTemplate` with parallel checks, a conditional publish task and a report task, runs it once and the grader reads the workflow status.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-079-lab-010-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-template-structure.sh` | The DAG tasks, dependencies, default parameter, `when` expression and the result conditions of `report` |
| `validate-run-succeeded.sh` | `ci-run-1` uses the template and has the phase `Succeeded` |
| `validate-parallel-timing.sh` | `lint` and `test` overlap in time and `package` starts after both |
| `validate-conditional-and-report.sh` | `publish` is `Skipped`, `report` and `package` are `Succeeded` |
