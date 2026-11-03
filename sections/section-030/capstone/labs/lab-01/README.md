---
estimated_duration: 40m
---

# Capstone: Delivery Contract

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

Staging and production both run 6.14.0. The learner promotes 6.15.0 to staging and then to production in two commits, verifies both deliveries and records which commit changed which environment.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-079-lab-030-capstone
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-promotion-order.sh` | Both overlays name 6.15.0 in separate commits; production is newer than staging |
| `validate-both-delivered.sh` | Both Applications are Synced and Healthy at the head commit and run 6.15.0; production has two ready replicas |
| `validate-delivery-record.sh` | delivery-record holds staging-commit, production-commit and version |
