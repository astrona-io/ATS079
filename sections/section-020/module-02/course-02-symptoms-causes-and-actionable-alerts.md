---
draft: true
exam_objectives:
- Incident Response in Platform Engineering
---
# Symptoms, Causes And Actionable Alerts

An alert is a message that asks a person to act. If the message arrives for conditions that need no action, people learn to ignore it, and the one alert that matters gets lost among the rest. The skill is to choose conditions that are worth waking someone for.

This part separates symptoms from causes, lists what makes an alert actionable and shows how severity connects an alert to the response.

## Symptoms and causes

A **symptom** is something a user or a calling service experiences: requests fail, pages are slow, a feature does not work. A **cause** is the reason inside the system: a node ran out of memory, a certificate expired, a Deployment has a bad image.

Alert on symptoms first. A symptom alert fires for every cause, including causes that nobody thought of. A cause alert, for example "CPU above 90 percent on a node", fires when the number is high, even when no user is affected, and it stays silent when the real cause is a different one. Cause signals still matter, but as evidence on a dashboard that the responder reads after the symptom alert, not as a page.

A platform has two kinds of users. The application teams use the platform's APIs, such as deploying a workload or creating a namespace. Their end users use the applications. A platform symptom is one of the platform's own users failing: deployments that do not roll out, pods that cannot start, builds that cannot run.

## What makes an alert actionable

An alert is actionable when all of these are true.

- **It needs a human now.** If a machine can fix it, automate the fix. If it can wait until morning, send a ticket and not a page.
- **It says what is wrong.** The text names the service, the symptom and the size, for example "scout: 12 percent of requests failed in 5 minutes".
- **It links to a first step.** A runbook, a written procedure for the alert, says what to check first.
- **It is rare enough to trust.** Each false or duplicate alert lowers trust in the next one.

An alert that fires every day and is always closed with no action is noise. Delete it or change it into a dashboard panel.

## Thresholds and duration

A condition that is true for one second is not an incident. Alert rules therefore add a duration: the condition must hold for a period, such as five minutes, before the alert fires. The same applies to the end: the alert stays until the condition has been false for a period, so it does not flap.

Kubernetes has the same idea inside its probes. A readiness probe has `failureThreshold`, the number of failures in a row before the container is marked not ready, and `periodSeconds`, the time between checks. The probe of the `scout` Deployment shows them:

<!-- astrona:playground:renew -->
```sh
kubectl -n starfleet get deploy scout -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}'
```

The output is the probe in JSON form. Fields that the manifest does not set show Kubernetes defaults when the object is read in full with `-o yaml`: a period of 10 seconds and a failure threshold of 3. A container that fails three checks in a row, about 30 seconds, leaves the Service endpoints. The short delay prevents one slow answer from removing a healthy pod.

## Severity

Severity ranks an incident by impact, so the response is proportional. One common scale has four levels.

- **Severity 1**: a full outage or data loss. A page goes out at once and the whole incident team joins.
- **Severity 2**: a major function is degraded for many users. A page goes out, and one responder leads.
- **Severity 3**: a minor function is degraded or one team is affected. A ticket is created, and work happens in office hours.
- **Severity 4**: a cosmetic or low-risk issue. It goes to the backlog.

The scale is an agreement inside an organisation, and the numbers can differ. What matters is that the definition is written down and that alerts carry a severity. The responder can change the severity when new evidence shows more or less impact.

## From alert to response

A good alert shortens the path to action: it fires on a symptom, says what is wrong, carries a severity and links to a runbook. The next question is how much failure users can tolerate, because that number decides when a symptom is serious enough to alert.

## Common pitfalls

> [!WARNING]
> An alert on one cause misses every other cause of the same symptom. An alert without a duration fires on single slow requests. Raising severity to get attention teaches the team to ignore the scale. A page that has no first step in its text makes the responder search for context in the middle of the incident.
