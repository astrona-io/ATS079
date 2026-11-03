---
estimated_duration: 45m
---

# Capstone: Release Pipeline With Retry, Output And Parallelism Limit

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The learner writes a release pipeline that combines a DAG, an output parameter with a matching dependency, a retry for a failing first attempt, a skipped task and a concurrency limit, and runs it twice with different parameters.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-079-lab-010-capstone
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-template-structure.sh` | Tasks, dependencies, output reference, retry strategy, parallelism and conditions of `release-pipeline` |
| `validate-runs-finished.sh` | `release-1` and `release-2` use the template with the right parameter and `Succeeded` |
| `validate-retry-and-data.sh` | `integration` has a failed first attempt and a successful last one, `package` received `1.4.2`, `publish` ran |
| `validate-skipped-publish.sh` | `publish` is `Skipped` in `release-2` |
| `validate-concurrency-limit.sh` | No more than two task pods overlap in `release-1` |
