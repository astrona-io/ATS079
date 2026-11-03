---
draft: true
exam_objectives:
- Incident Response in Platform Engineering
---
# Indicators, Objectives And Error Budgets

No service is available all the time, and trying for a perfect score costs more than users value. A team needs a number that says how much failure is acceptable, so that it can tell a normal bad minute from an incident and decide when to stop shipping features and fix reliability.

This part defines the three terms that give that number, a service level indicator, a service level objective and an error budget, and shows the calculation with real figures.

## Indicator, objective, agreement

A **service level indicator (SLI)** is a measurement of how the service behaves for users. A common SLI is the share of requests that succeed: successful requests divided by all requests. Another is the share of requests that finish faster than a limit, such as 300 milliseconds.

A **service level objective (SLO)** is the target for an SLI over a time window, for example "99.9 percent of requests succeed over 30 days". The team sets it, and it must be a number that users can live with and the team can reach.

A **service level agreement (SLA)** is a contract with a customer that names consequences, usually money, when the target is missed. An SLA is looser than the internal SLO, so the team notices a problem before the contract is broken.

## The error budget

The **error budget** is the failure that the SLO allows: 100 percent minus the objective. With an SLO of 99.9 percent, the budget is 0.1 percent.

Over a window, the budget can be counted in requests or in time. For a window of 30 days, there are 30 times 24 times 60 equal to 43,200 minutes. The budget of 0.1 percent of 43,200 minutes is 43.2 minutes of full downtime in 30 days. An SLO of 99.99 percent gives 4.32 minutes. Each extra nine divides the budget by ten, and it costs far more effort to deliver.

For requests, a service that handles 10 million requests in the window may fail 10,000 of them at 99.9 percent. If 8,000 have failed on day 20, 80 percent of the budget is spent with a third of the window left.

## Using the budget

The budget turns reliability into a decision. While plenty of budget is left, the team can ship changes and take risks. When the budget is nearly spent, the team slows down changes and works on reliability until the window recovers. The rule is agreed in advance, so a discussion about risk does not depend on who speaks loudest.

The budget also drives alerting. An alert that fires when the service fails right now misses a slow leak, and an alert on a single failed request fires too often. A **burn rate** is how fast the budget is consumed compared with a steady spend that would use exactly the whole budget at the end of the window. A burn rate of 1 uses the budget exactly over the window. A burn rate of 14.4 sustained for one hour uses 2 percent of a 30-day budget, since 14.4 times 1 hour is 14.4 hours and 14.4 divided by 720 hours is 2 percent. Teams page on a high burn rate over a short window and open a ticket for a low burn rate over a long window.

## Measuring in Kubernetes

Kubernetes itself does not calculate SLOs. A monitoring system collects the SLI from a load balancer, an ingress controller or the application, and calculates the budget. What `kubectl` shows is a first approximation for one workload: the ready replicas against the wanted replicas.

<!-- astrona:playground:renew -->
```sh
kubectl -n starfleet get deploy scout -o jsonpath='{.status.readyReplicas}/{.spec.replicas}{"\n"}'
```

The command prints the ready count over the wanted count. A value such as `2/2` means every replica is ready. It describes the state at one moment and not the history over 30 days, so it cannot replace an SLI. Use it to confirm the state while an incident is going on.

## Choosing good indicators

Measure what the user experiences, at the edge of the service. The four signals that many teams start with are latency, traffic, errors and saturation, which is how full the most constrained resource is. A platform can apply them to its own interfaces: the time to schedule a pod, the share of deployments that roll out, the error rate of its API and the fill level of its quotas.

Choose few SLOs and write them down with the window and the measurement. A service with twenty SLOs has none that the team can use during an incident.

An objective gives the team a number for what counts as bad. The next question is what the responder does in the first minutes of a real alert.

## Common pitfalls

> [!WARNING]
> An SLO of 100 percent leaves no budget, so every change breaks it. A budget in minutes only fits an outage of the whole service, not a partial failure. An SLA that equals the SLO leaves no time to react before a penalty. A `kubectl` readiness count is a moment, not a measurement over the window.
