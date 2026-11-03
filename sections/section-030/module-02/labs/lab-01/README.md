---
estimated_duration: 20m
---

# Lab: Switch Blue/Green Traffic And Record The Release

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

Two environments of `scout` run side by side and the Service sends traffic to blue. The learner sets rolling update fields on blue, switches the Service selector to green, keeps blue for a rollback and writes a release record.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-079-lab-030-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-traffic-switched.sh` | The selector is green, both endpoints are green pods and a request returns 6.15.0 |
| `validate-blue-kept.sh` | `scout-blue` has two ready replicas and the rolling update fields |
| `validate-release-record.sh` | `release-record` has the strategy, the live and previous color and the rollback command |
