---
estimated_duration: 40m
---

# Capstone: Environment Generation

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The project scout-team exists. The learner writes an ApplicationSet that generates staging, production and preview, promotes staging and production in two commits and retires preview by removing its element.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-050/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-050/capstone/labs/lab-01
astrona destroy ats-079-lab-050-capstone
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-applicationset-shape.sh` | scout-envs is a templated list with the finalizer, prune and selfHeal, and owns both Applications |
| `validate-promoted.sh` | Both overlays name 6.15.0 in two commits and both Applications are delivered at the head commit |
| `validate-preview-retired.sh` | The preview element, Application and objects are gone and the namespace remains |
