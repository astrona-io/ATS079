---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Git As The Handoff: Promotion By Commit

The previous part defined the delivery contract as an artifact plus a change in Git. This part follows that change through the system. A promotion, which means moving a new version into an environment, is a commit that changes one line. Argo CD then does the work that a deploy script would do in a push-based pipeline. Knowing exactly how Argo CD notices the commit, what it compares and what it changes lets you predict how long a delivery takes and where it can stop.

## Push and pull delivery

In **push delivery**, the pipeline connects to the cluster and applies the manifests itself. The pipeline needs credentials for every cluster it delivers to, and the cluster state is whatever the last run of the pipeline left.

In **pull delivery**, which is the model of Argo CD, an agent inside the environment reads the desired state from a repository and applies it. The pipeline only needs to write to the repository. The agent needs read access to the repository and the permissions in its own cluster. The direction of the connection is from the cluster to Git, so the cluster does not need to accept connections from the build system.

## What the components of Argo CD do

Argo CD runs as several components in the namespace `argocd`.

- The **repo-server** clones the repository and renders the manifests for the path of an Application. For a Kustomize path, it runs the Kustomize build and returns plain Kubernetes objects. It keeps no state of its own about the cluster.
- The **application controller** compares the rendered manifests with the live objects in the cluster. It sets the sync status and the health status in the Application, and it runs the sync when it is allowed to.
- The **API server** serves the web page and the command-line client. This module does not use it, because everything is read from the Application object with `kubectl`.

An **Application** is a Kubernetes custom resource that names a source (repository, revision and path), a destination (cluster and namespace) and a project. It does not contain the manifests. It points at them.

## How a commit becomes a change

```mermaid
sequenceDiagram
    participant CI as CI job
    participant Git as Git repository
    participant RS as repo-server
    participant AC as application controller
    participant K as Kubernetes API
    CI->>Git: push commit with new image tag
    AC->>RS: refresh: render the path at main
    RS->>Git: fetch and build manifests
    RS-->>AC: desired manifests
    AC->>K: read live objects and compare
    AC->>K: sync: apply the difference
```

The refresh in the second line is triggered in one of two ways. By default the controller refreshes each Application about every three minutes, which is why a commit does not show up at once. A refresh can also be requested by an annotation on the Application, `argocd.argoproj.io/refresh`, and a webhook from the Git server can request one when a push happens. After the refresh, the Application is `OutOfSync` if the rendered manifests differ from the live objects.

If the Application has an `automated` sync policy, the controller starts a sync as soon as the Application is `OutOfSync`. It applies the manifests to the namespace, and the Deployment controller then performs the rolling update, which Argo CD does not control. If there is no automated policy, the Application stays `OutOfSync` until a person starts the sync.

<!-- astrona:playground:renew -->
## Try it: promote by commit

In the playground, staging runs 6.14.0. The overlay file `overlays/staging/kustomization.yaml` decides the tag. Clone the repository from the Git server that runs in the cluster. It is reachable from your machine on port 3000:

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
```

Then save the overlay with the new tag.

Save this as `overlays/staging/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: starfleet-staging
resources:
  - ../../base
labels:
  - pairs:
      environment: staging
images:
  - name: ghcr.io/stefanprodan/podinfo
    newTag: 6.15.0
replicas:
  - name: scout
    count: 1
patches:
  - path: message.yaml
```

Commit and push it, as a CI job would after a build:

```sh
git add overlays/staging/kustomization.yaml
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "promote scout to 6.15.0 in staging"
git push origin main
```

The push is the whole contract from the point of view of CI. Nothing in the cluster has changed yet. Check it, first by waiting a moment and reading the sync status, which is probably still `Synced` because the controller has not refreshed:

```sh
kubectl -n argocd get application scout-staging
```

Ask for the refresh and watch the delivery:

```sh
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-staging rollout status deploy/scout --timeout=180s
kubectl -n starfleet-staging get deploy scout -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

The annotation asks the controller to refresh the Application without waiting for the interval. The value `hard` also clears the cached manifests. The rollout completes, and the image now ends with `6.15.0`. Argo CD recorded the delivery in the history of the Application:

```sh
kubectl -n argocd get application scout-staging -o jsonpath='{range .status.history[*]}{.id}{" "}{.revision}{" "}{.deployedAt}{"\n"}{end}'
```

There are two entries. The newest one has the revision of your commit. The history is part of the evidence for this change.

## Properties that follow from this design

- **A retry is safe.** If a CI job pushes the same content twice, the second `git commit` has nothing to commit, and the repository does not change. Delivery is driven by the content of Git and not by the number of pipeline runs.
- **Concurrent writers collide in Git.** If two jobs push to the same branch, the second push is rejected as not fast-forward. The job must fetch and rebase, or fail. The conflict is visible, which is better than two deploy scripts racing in the cluster.
- **A rollback is a commit.** To go back, revert the commit. Argo CD delivers the revert in the same way as any other change.
- **The delay is part of the contract.** Between the push and the sync there is up to one refresh interval. A pipeline that must wait for the delivery has to poll the Application, and not assume that the push finished it.

This part followed one commit through the components. The next part looks at what can be read from the result, and at the signals that look like success and are not.

## Common pitfalls

> [!WARNING]
> After a push, the Application can stay `Synced` for up to the refresh interval, because Argo CD has not looked at Git yet. A successful push means the contract was written, not that the environment changed. Two pipelines that push to the same branch need a rebase step, or the second one fails.
