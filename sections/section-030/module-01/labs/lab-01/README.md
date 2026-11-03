---
estimated_duration: 25m
---

# Lab: Promote Staging By Commit And Record The Delivery

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

Staging runs 6.14.0. The learner promotes 6.15.0 by a commit, waits for Argo CD to deliver it and writes a delivery record as a ConfigMap.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-079-lab-030-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-promoted-in-git.sh` | The staging overlay in Git names 6.15.0 and the change is a new commit |
| `validate-delivered-by-argocd.sh` | scout-staging is Synced and Healthy at the head commit; Argo CD owns the Deployment, which runs 6.15.0 |
| `validate-delivery-record.sh` | delivery-record has environment, version, the full head commit and health |
