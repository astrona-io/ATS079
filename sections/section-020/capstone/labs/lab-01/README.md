---
estimated_duration: 40m
---

# Capstone: Incident Response

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

Three services are down for three different reasons: an image tag that does not exist, a missing ConfigMap key and a readiness probe on the wrong port. The learner classifies and repairs each one and records the causes.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS079.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-079-lab-020-capstone
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-and-bridge.sh` | `scout` and `bridge` run 6.15.0, are ready, were updated in place, and `bridge` probes `/readyz` on the application port |
| `validate-probe-config.sh` | `probe` still reads `MODE` from `probe-config` key `mode`, the key exists and the pod is ready |
| `validate-incident-record.sh` | One cause per service with the words image, ConfigMap and readiness, and status `resolved` |
