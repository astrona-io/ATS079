---
estimated_duration: 25m
---

# Lab: Revert A Bad Release And Make Argo CD Enforce Git

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

A commit set a tag that does not exist, and staging is unhealthy. The learner reverts it in Git, waits for the delivery and turns on prune and selfHeal.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-079-lab-040-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-reverted-in-git.sh` | The head commit is a revert, the bad commit is in the history and staging names 6.14.0 |
| `validate-delivered.sh` | scout-staging is Synced and Healthy at the head commit and runs 6.14.0 |
| `validate-enforces-git.sh` | prune and selfHeal are on, and a hand edit of the replicas is undone |
