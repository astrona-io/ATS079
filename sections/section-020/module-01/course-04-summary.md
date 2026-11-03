---
draft: true
exam_objectives:
- Incident Response in Platform Engineering
---
# Summary

A platform incident is defined by its impact, and the response follows a fixed order: detect and declare, mitigate, resolve and learn. Roles keep the work orderly. The incident commander decides, the operations lead changes the system, the communications lead informs others and the scribe writes the timeline. Mitigation comes before root cause analysis because the goal during an incident is to restore the agreed service level, and a blunt but safe action such as a rollback is allowed to do that.

Kubernetes records its own evidence. A Deployment reports the conditions `Available` and `Progressing`. It keeps one ReplicaSet for each revision of the pod template. Pods report a state with a reason, and the kubelet and the controllers write events that expire after about one hour. Reading this evidence in a fixed order, from the Deployment to the ReplicaSets, the pods, the events and the logs, finds the failing stage quickly. A container that never started has no logs, so its events are the evidence.

A rolling update replaces pods in steps. With the default strategy and two replicas, the controller creates one new pod and removes an old pod only after the new one is ready, so a release that cannot start stalls and the old pods keep serving. The Deployment reports `ProgressDeadlineExceeded` after the deadline, and Kubernetes does not roll back by itself. `kubectl rollout undo` writes the previous pod template back and creates a new revision. It restores the template only, and not the other objects that a release changed.

Pod faults fall into four classes with different marks. `ImagePullBackOff` means the image could not be pulled. `CreateContainerConfigError` means a referenced ConfigMap or Secret key is missing. `CrashLoopBackOff` means the process starts and exits, and its previous logs show why. A running pod that is not ready failed its readiness probe, and it receives no Service traffic. The class decides the mitigation, and the incident record keeps the class, the evidence and the action for the review.

Key facts:

- Severity is chosen from impact and may change during the incident.
- Mitigation restores service. Resolution removes the cause. Both are written in the timeline.
- Events expire after about one hour, so copy them into the record.
- A rollback restores the pod template of the Deployment and nothing else.
- Fix a missing configuration key in the ConfigMap, not by removing the reference.

<!-- astrona:playground:destroy -->
