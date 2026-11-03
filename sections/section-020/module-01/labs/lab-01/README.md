---
estimated_duration: 20m
---

# Lab: Roll Back A Bad Release And Write The Incident Record

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

A release with a bad image tag has stalled the rollout of `scout`. The learner reads the evidence, rolls back, and writes the incident record as a ConfigMap.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-079-lab-020-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-service-restored.sh` | `scout` runs 6.15.0 with two ready replicas, a complete rollout and two ready endpoints |
| `validate-history-kept.sh` | The Deployment was not recreated: the ReplicaSet of the bad release exists with no replicas |
| `validate-incident-record.sh` | `incident-record` has severity, cause (names 6.15.99), mitigation `rollback`, status `resolved` and a timeline |
