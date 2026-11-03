---
draft: true
exam_objectives:
- Incident Response in Platform Engineering
---
# Summary

A platform team detects problems from signals. Metrics show that something changed, logs show what a process said, events show what the platform did to an object, and traces show where a request spent its time. Pod status, events and container logs are available in every cluster and are the fastest first evidence. Events expire after about an hour, so the team saves them early.

Alerts should describe symptoms that users feel, because a symptom alert fires for every cause. An actionable alert needs a human now, says what is wrong, links to a first step and fires rarely enough to be trusted. A duration on the rule prevents alerts for single slow requests. Severity ranks impact on a written scale so that the response is proportional.

A service level indicator measures how the service behaves for users. A service level objective sets a target for it over a window, and the error budget is the failure that the target allows. A 99.9 percent objective over 30 days allows 43.2 minutes of full downtime. The budget decides when to ship and when to fix reliability, and the burn rate of the budget decides when to page.

The first pass of an incident lists unhealthy pods, classifies each failure by its status, reads events and exit codes and sets the scope. Many workloads failing the same way at the same time point to a shared cause. One failing workload points to its own release. The findings go into the incident record as they are found.

Key facts:

- Four signals: metrics, logs, events and traces.
- Alert on symptoms and keep causes for dashboards.
- Error budget equals 100 percent minus the objective.
- Exit code 137 means the process was killed with SIGKILL.
- Scope first, then fix.

<!-- astrona:playground:destroy -->
