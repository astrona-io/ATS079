---
draft: true
exam_objectives:
- GitOps for Application Environments
---
# Application Source And Destination

An Argo CD Application is a pair: where the desired state is read from, and where it is applied. This part takes the pair apart field by field, shows how a revision can be a moving branch or a fixed commit, and explains how the identity of an Application and of its objects is recorded. It ends with an experiment that shows the difference between following a branch and pinning a commit.

## The source

The source says what to render. Three fields locate it.

- `repoURL` names the Git repository. Argo CD needs credentials for a private repository. They are stored as a Secret in the namespace `argocd` with the label `argocd.argoproj.io/secret-type: repository`, and the repo-server uses them when it clones.
- `targetRevision` names what to read. It can be a branch, a tag or a full commit ID. A branch and a tag are names that resolve to a commit, and the resolved commit can change. A full commit ID never changes.
- `path` names the directory in the repository whose content is rendered.

The repo-server decides how to render the directory by looking at its content. A directory with a `kustomization.yaml` is built with Kustomize. A directory with a `Chart.yaml` is rendered as a Helm chart. Otherwise, the plain manifests in it are read. The rendering is a pure function of the content at the revision, so the same revision always produces the same manifests, and this is what makes the comparison meaningful.

The result of the resolution is stored in the status. `status.sync.revision` holds the commit that was compared, always as a full commit ID, even when `targetRevision` is a branch name.

## The destination

The destination says where to apply. It has two parts.

- The cluster, named either by `server`, the address of its API server, or by `name`, the name under which the cluster was registered. For the cluster that Argo CD runs in, the address is `https://kubernetes.default.svc`.
- The `namespace`, which is the namespace for objects that do not name one. A Kustomize `namespace` field in the overlay sets the namespace in the rendered objects. Both should agree, and the destination namespace is also the one that the project checks.

If the namespace does not exist, the sync fails, unless the sync option `CreateNamespace=true` is set. That option creates the namespace but does not manage it afterwards.

## Identity

An Application is identified by its name in the namespace `argocd`. The objects that it manages are identified by the tracking annotation `argocd.argoproj.io/tracking-id`, written as `application:group/kind:namespace/name`. Argo CD finds the objects of an Application by this annotation. The consequence is that renaming an Application does not move its objects: the new Application will see objects that carry another name in the annotation. Two Applications that render the same object conflict over it.

## Following and pinning

A branch name follows the work. Every new commit changes the desired state, and the Application delivers it. A commit ID pins the work. New commits are ignored until someone changes the field. Neither is correct for all cases.

| `targetRevision` | Behavior | Typical use |
| --- | --- | --- |
| `main` | Follows the branch. Every merged change is delivered. | A shared environment that always runs the latest approved state. |
| A tag | Follows the tag, which usually does not move. | A release that is promoted by creating a tag. |
| A full commit ID | Pinned. Nothing changes until the field is edited. | An environment that must not move, or a reproduction of an incident. |

The pin is a policy decision stored in the Application. If it is forgotten, an environment silently stops receiving changes while the pipeline reports success.

<!-- astrona:playground:renew -->
## Try it: follow a branch and pin a commit

Create an Application for staging. Save this as `scout-staging.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: scout-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
    targetRevision: main
    path: overlays/staging
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet-staging
  syncPolicy:
    automated: {}
```

Apply it:

```sh
kubectl apply -f scout-staging.yaml
```

Check it: wait until the Application is `Synced` and `Healthy`, and read the revision that was compared.

```sh
kubectl -n argocd get application scout-staging -o jsonpath='{.status.sync.status} {.status.health.status} {.status.sync.revision}{"\n"}'
```

The revision is a full commit ID, although `targetRevision` is `main`. Pin the Application to that commit:

```sh
SHA="$(kubectl -n argocd get application scout-staging -o jsonpath='{.status.sync.revision}')"
kubectl -n argocd patch application scout-staging --type merge -p "{\"spec\":{\"source\":{\"targetRevision\":\"$SHA\"}}}"
```

Now change the desired state in Git. Clone the repository, which is reachable from your machine on port 3000:

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
```

Save this as `overlays/staging/message.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scout
spec:
  template:
    spec:
      containers:
        - name: scout
          env:
            - name: PODINFO_UI_MESSAGE
              value: staging v2
```

Apply it: commit, push and refresh.

```sh
git add overlays/staging/message.yaml
git -c user.name=ci -c user.email=ci@starfleet.local commit -m "change the staging message"
git push origin main
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
```

Check it: the Application is still `Synced`, at the old revision, and the Deployment still has the old message.

```sh
kubectl -n argocd get application scout-staging -o jsonpath='{.status.sync.status} {.status.sync.revision}{"\n"}'
kubectl -n starfleet-staging get deploy scout -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="PODINFO_UI_MESSAGE")].value}{"\n"}'
```

The commit exists in Git, and the pinned Application does not see it. Follow the branch again and read the result:

```sh
kubectl -n argocd patch application scout-staging --type merge -p '{"spec":{"source":{"targetRevision":"main"}}}'
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-staging rollout status deploy/scout --timeout=180s
kubectl -n starfleet-staging get deploy scout -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="PODINFO_UI_MESSAGE")].value}{"\n"}'
```

The message is now `staging v2`, and the revision in the status is the new commit.

## Common pitfalls

> [!WARNING]
> A pinned `targetRevision` hides new commits without any error, and the Application keeps showing `Synced`. Check the field first when an environment does not receive a change. A branch name is not a version: the same Application can render different manifests tomorrow. Also keep the destination namespace and the Kustomize `namespace` equal, because the project checks only the destination.
