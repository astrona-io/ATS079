---
estimated_duration: 25m
---

# Lab: Environments In A Project With Their Own Deletion Policy

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

No project and no Application exist. The learner creates the project scout-team for staging and production, creates two Applications with different finalizer policies and shows that the preview namespace is refused.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-050/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-050/module-01/labs/lab-01
astrona destroy ats-079-lab-050-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-project-boundary.sh` | scout-team allows one repository and the staging and production namespaces, with no wildcards |
| `validate-applications-delivered.sh` | Both Applications are in scout-team, delivered at the head commit and tracked; only production has the finalizer |
| `validate-preview-refused.sh` | A temporary Application for starfleet-preview has InvalidSpecError and nothing exists there |
