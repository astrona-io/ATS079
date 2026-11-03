---
estimated_duration: 20m
---

# Lab: Scope An Alert And Write The Detection Record

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

Two workloads fail next to a healthy one. The learner reads pod status, events and the exit code, calculates an error budget and writes the detection record as a ConfigMap, without changing the workloads.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-079-lab-020-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-signals-classified.sh` | `detection-record` names `probe`, `beacon` and `scout` correctly and the exit code matches the pod status |
| `validate-error-budget.sh` | The budget is 43.2 minutes and severity and signal are set |
| `validate-nothing-changed.sh` | The three Deployments still have generation 1 |
