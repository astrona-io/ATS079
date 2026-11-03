---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Health, Diff And Sync Options

An Application has two separate statuses. The sync status says whether the live state equals Git. The health status says whether the live objects work. They can disagree: an application can be `Synced` and `Degraded` at once, when Git was applied exactly and the pods crash. Reading both avoids false confidence.

This part explains how Argo CD calculates each status, how to read the difference between Git and the cluster, and which sync options change how objects are applied.

## Sync status

The sync status is `Synced` when the rendered manifests from Git equal the live objects, and `OutOfSync` when they differ. Argo CD compares only the fields that the manifest sets. A field that Kubernetes fills in, such as `status` or a default value, does not count as a difference.

Read the status of the playground Application:

<!-- astrona:playground:renew -->
```sh
kubectl -n argocd get application scout-staging -o jsonpath='sync={.status.sync.status} revision={.status.sync.revision}{"\n"}'
```

The revision is the Git commit that Argo CD compared. After a push, it can still show the old commit until Argo CD refreshes, by default about every three minutes, or until you ask for a refresh.

## Health status

Argo CD has built-in health checks for common kinds.

- A Deployment is `Healthy` when the rollout is complete and the pods are ready. It is `Progressing` during the update and `Degraded` when the rollout misses its progress deadline.
- A Service is `Healthy` when it exists. A Service of type LoadBalancer waits for an address.
- A Job is `Healthy` when it completed. A failed Job is `Degraded`.
- A custom resource has no built-in check unless Argo CD ships one or you add a custom check in a Lua script.

The health of an Application is the worst health of its resources. The automatic sync does not wait for health to start, but a sync wave does: the next wave starts only when the objects of the earlier wave are healthy.

Print the health of the Application and of each resource:

```sh
kubectl -n argocd get application scout-staging -o jsonpath='health={.status.health.status}{"\n"}{range .status.resources[*]}{.kind}{"\t"}{.name}{"\t"}{.status}{"\t"}{.health.status}{"\n"}{end}'
```

## Diff

When the status is `OutOfSync`, the diff shows which fields differ. The web page shows it in the Application view. The command line tool prints it with `argocd app diff scout-staging`. The diff lists the live value and the desired value for each changed field.

To see a drift, scale the Deployment by hand and read the status:

```sh
kubectl -n starfleet-staging scale deploy/scout --replicas=2
kubectl -n argocd get application scout-staging -o jsonpath='sync={.status.sync.status}{"\n"}'
```

The status becomes `OutOfSync` after the next comparison, because Git says 1 replica and the cluster has 2. With `automated: {}` and no self-heal, Argo CD reports the drift and does not undo it. Argo CD only looks at fields that Git sets, so a field that another controller changes on purpose, for example the replica count under a HorizontalPodAutoscaler, needs to be ignored.

## Ignoring differences

The field `spec.ignoreDifferences` of an Application lists fields that the comparison skips.

```yaml
spec:
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas
```

The entry tells Argo CD not to count the replica count as a difference for Deployments. Use it for fields that another controller owns, and not to hide a real mistake.

## Sync options

Sync options change how Argo CD applies objects. They are set in `spec.syncPolicy.syncOptions` on the Application, or in an annotation on one object.

- `CreateNamespace=true` creates the target namespace.
- `Prune=false` on an object keeps it even when Git no longer has it.
- `ServerSideApply=true` applies with server-side apply, which handles large objects and shared ownership better than the client-side annotation method.
- `Replace=true` replaces objects instead of patching them, which deletes and recreates fields. Use it only when a patch cannot work.
- `PruneLast=true` prunes only after the rest of the sync succeeded.
- `ApplyOutOfSyncOnly=true` applies only the objects that differ, which speeds up large Applications.

The Application of the playground already uses `CreateNamespace=true`. Print its options:

```sh
kubectl -n argocd get application scout-staging -o jsonpath='{.spec.syncPolicy.syncOptions}{"\n"}'
```

Sync options are narrow tools. Each one changes a default for a reason, so write the reason next to it in the repository.

## Reading the two statuses together

Four combinations cover most cases. `Synced` and `Healthy` is the goal. `Synced` and `Degraded` means Git was applied and the application is broken, so look at the pods and probably roll back the commit. `OutOfSync` and `Healthy` means a drift or a pending change. `OutOfSync` and `Degraded` needs both checks.

## Common pitfalls

> [!WARNING]
> `Synced` does not mean the application works, so read the health too. The revision in the status can be older than the head of Git until the next refresh. `Replace=true` can delete data in fields that you did not mean to change. An ignoreDifferences rule that is too wide hides real drift.
