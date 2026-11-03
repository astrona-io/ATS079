---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Summary

GitOps rests on four principles: the desired state is declarative, it is versioned and immutable, it is pulled by an agent, and it is continuously reconciled. Each principle has a component. Git stores the state and its history. The repo-server renders manifests and holds no cluster credentials. The application controller compares the rendered state with the live state and applies the difference. The cluster is the runtime. The AppProject, Argo CD RBAC, Kubernetes RBAC and the permissions of the Git host form the policy.

The unit of management is the Application, with one source and one destination. The agent owns the objects that carry its tracking annotation, and no others. It needs an installation and repository credentials before it can start, and those are created outside the loop. If the Git host or the agent is down, the workload keeps running and only change stops.

Reconciliation compares the desired state with the live state. A comparison runs on a new commit and on a change in the cluster, and a sync applies the difference. The sync policy has three switches. `automated` delivers new commits without a person. `selfHeal` undoes changes made in the cluster. `prune` deletes objects that left Git. Each is off unless set, because each removes a human decision: selfHeal removes hand edits and prune removes objects.

Policy limits the agent where it writes. An Application that is not allowed to read a repository or write to a destination gets an `InvalidSpecError` condition, and nothing is applied. The default project allows everything, so it is not a boundary. The cluster sees the controller as the author of every change. The person is in the Git record, reached through `status.sync.revision`. A change made with `kubectl` shows up as another manager in `managedFields`.

A bad release is undone by a revert commit, which adds to the history and is delivered like any change. Deleting the bad commit from history or rolling back by hand leaves Git and the cluster in disagreement.

Key facts:

- The four principles: declarative, versioned and immutable, pulled automatically, continuously reconciled.
- `automated: {}` delivers commits only. Self-heal and prune are separate switches.
- A project refusal appears as `InvalidSpecError` and creates no objects.
- Every change in the cluster is made by the controller identity, and Git names the person.
- A rollback is a revert commit.

<!-- astrona:playground:destroy -->
