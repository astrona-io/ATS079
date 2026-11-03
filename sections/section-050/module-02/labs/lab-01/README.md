---
estimated_duration: 25m
---

# Lab: One ApplicationSet From The Folders Of A Repository

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

No Application and no ApplicationSet exist. The learner writes an ApplicationSet with a Git directory generator that includes `overlays/*` and excludes `overlays/preview`, and checks the generated Applications and the self-heal policy.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-applicationset-shape.sh` | One Git directory generator with an include and an exclude, Go templates, placeholders |
| `validate-generated-applications.sh` | Staging and production are generated, owned and delivered; preview is absent |
| `validate-self-healing.sh` | Prune and selfHeal are on, and a hand edit of production is undone |
