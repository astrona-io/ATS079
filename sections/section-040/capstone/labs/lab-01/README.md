---
estimated_duration: 35m
---

# Capstone: Policy Boundary

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

Staging is in the default project. The learner creates the project scout-team, moves staging into it and proves that an Application for production is refused.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-079-lab-040-capstone
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-project-boundary.sh` | scout-team allows one repository and one destination, with no wildcards |
| `validate-staging-in-project.sh` | scout-staging is in scout-team and is Synced and Healthy |
| `validate-production-refused.sh` | scout-production-attempt has InvalidSpecError and nothing exists in starfleet-production |
