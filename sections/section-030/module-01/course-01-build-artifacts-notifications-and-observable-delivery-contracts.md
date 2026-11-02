---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Build Artifacts, Notifications And Observable Delivery Contracts

GitOps tooling often connects to build systems, artifact registries, notification services and observability backends. These integrations can make delivery understandable and responsive. They also create additional trust and failure boundaries. A useful design explains what each system contributes and which authority it needs, rather than combining every function under one universal deployment credential.

Continuous integration can validate source, build an artifact and publish it under a known identity. It can then propose or record an approved desired-state change according to repository policy. The management agent obtains that intent and applies it to the target. This separation lets build automation work without necessarily holding the same target authority as the reconciler.

Artifact provenance connects the source revision and build inputs to the produced content. The desired declaration then selects that content, and feedback identifies the version evaluated by the agent. If a moving image tag is reused without resolved identity, the chain becomes ambiguous. Operators may know the release name while not knowing which bytes reached production.

Notifications have two common roles. A source-change event can prompt earlier evaluation, while an outcome message can inform people or another system. Neither role replaces the state store's history. A missed source event should be recoverable through ordinary agent retrieval. A failed outcome notification should not be mistaken for proof that target reconciliation failed.

Consider an agent that applies a version successfully but cannot send its completion message because a chat integration is unavailable. Runtime state and notification delivery have different outcomes. Conversely, a perfectly delivered message can report an apply failure. Monitoring the channel and the described operation separately prevents a green notification receipt from becoming an invented deployment-health claim.

Observability helps assess runtime outcomes and control behavior. Agent metrics can show reconciliation duration, failures or stale source access. Application indicators can show whether users receive acceptable service. These populations differ. A fast reconciliation duration does not establish low application latency, and an empty error query does not automatically establish healthy operation if telemetry delivery failed.

Progressive delivery can use measurements as policy inputs. The controller needs a defined metric population, time window and handling of missing or failed queries. An integration that treats every empty result as success can promote a release during an observability outage. The decision should preserve uncertainty and follow the configured policy rather than inventing positive evidence.

Credentials should match each integration. A notification service needs permission to send to intended destinations, not unrestricted source writing. A build publisher needs a controlled artifact role. An image-update automation path may need a narrow desired-state write role. Separating these identities narrows compromise impact and makes audit evidence more interpretable.

Retries need stable operation meaning. A duplicated event should not create a second unrelated environment or repeatedly trigger a destructive action. Some systems use idempotent updates or operation identifiers to manage uncertain acknowledgements. The actual contract should be explicit because event delivery is not universally exactly once.

A good integration report connects approved source, artifact identity, evaluated intent and observed outcome. It names channel failures separately and explains which user-facing evidence remains uncertain. That approach gives students a concrete way to assess interoperability without assuming that a collection of connected tools automatically provides trustworthy delivery.

Continuous integration validates frequently integrated source changes and can create artifacts. Continuous delivery maintains a releasable path with the possibility of an explicit production decision. Continuous deployment automates that release decision after the required conditions are met. These practices can cooperate with GitOps: CI creates and verifies content, an approved change updates desired intent, and the agent realizes it. A build passing is therefore neither approval nor proof of runtime health. The platform should expose each transition and the role that owns it, especially when an application team chooses release timing while shared automation performs target changes.

## Common pitfalls

> [!WARNING]
> Notification delivery, agent success and application health are different evidence. Avoid one credential for every integration and do not treat missing measurements as success. Preserve content identity and recoverable behavior when events are duplicated or missed.
