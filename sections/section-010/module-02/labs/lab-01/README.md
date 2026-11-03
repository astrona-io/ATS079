---
estimated_duration: 25m
---

# Lab: Build Once And Name The Artifact

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster has Argo Workflows and no pipeline. The learner writes a `WorkflowTemplate` with a shared workspace volume and an output parameter that carries the image reference, runs it once and the grader reads the workflow status.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-079-lab-010-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-template-structure.sh` | The workspace claim, parameter defaults, task order and the output parameter `image` |
| `validate-run-succeeded.sh` | `build-run-1` uses the template and has the phase `Succeeded` |
| `validate-image-reference.sh` | The package task published `scout:1.4.0-3f9c2ab` |
| `validate-deliver-input.sh` | `deliver` received the reference and the tasks succeeded |
