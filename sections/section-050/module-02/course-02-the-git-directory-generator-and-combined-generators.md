---
draft: true
exam_objectives:
- GitOps for Application Environments
---
# The Git Directory Generator And Combined Generators

The Git directory generator turns the folders of a repository into Applications. In the example repository `scout-deploy`, the folder `overlays` holds one folder for each environment. One ApplicationSet can deliver all of them, and a new folder becomes a new Application on the next refresh of the generator.

## A directory generator

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: scout-envs
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - git:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        revision: main
        directories:
          - path: overlays/*
          - path: overlays/preview
            exclude: true
  template:
    metadata:
      name: 'scout-{{ .path.basename }}'
    spec:
      project: default
      source:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        targetRevision: main
        path: '{{ .path.path }}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'starfleet-{{ .path.basename }}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

The `directories` list has two entries. The first matches every folder directly below `overlays`. The second has `exclude: true` and removes `overlays/preview` from the matches. Excludes win over includes, whatever the order.

The generator gives each folder these variables: `.path.path` is the full path, `.path.basename` is the last element, and `.path.segments` is the list of elements. In the template, `scout-{{ .path.basename }}` becomes `scout-staging` for the folder `overlays/staging`.

## How it refreshes

The generator reads the repository on a timer, by default every three minutes. The Application controller does not trigger an immediate read when a folder appears, unless a webhook from the Git server calls Argo CD. If you add a folder and nothing appears, wait for the interval or restart the generator by annotating the ApplicationSet.

## What a removed folder does

When a folder disappears from the repository, its parameter set disappears from the result. The ApplicationSet controller deletes the Application that it created for it. If the Application has the cascade finalizer, its objects are deleted too. Set `syncPolicy.preserveResourcesOnDeletion: true` on the ApplicationSet to keep the objects when an Application is removed.

## Matrix and merge

The **matrix generator** takes two child generators and produces every combination. A Git directory generator for environments and a cluster generator for clusters give one Application for each environment on each cluster.

```yaml
generators:
  - matrix:
      generators:
        - git:
            repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
            revision: main
            directories:
              - path: overlays/*
        - clusters:
            selector:
              matchLabels:
                fleet: scout
```

The result has one set per folder and cluster pair. The number of Applications is the product of the two counts, so check the size before you apply it.

The **merge generator** combines sets that share a key. A base generator provides the sets, and later generators override or add fields for sets with the same key. It is useful for defaults with a few exceptions, such as one environment with a different replica count.

## Create it

<!-- astrona:playground:renew -->
Save the ApplicationSet above in a file named `scout-envs.yaml` and create it:

```sh
kubectl apply -f scout-envs.yaml
kubectl -n argocd get applicationset scout-envs
kubectl -n argocd get applications
```

After the first read of the repository, the Applications `scout-staging` and `scout-production` appear. The folder `overlays/preview` is excluded, so there is no `scout-preview`. Read who owns an Application:

```sh
kubectl -n argocd get application scout-staging -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}{"\n"}'
```

The output is `ApplicationSet/scout-envs`. An Application with an owner is managed by the ApplicationSet, and a hand edit of its spec is overwritten.

## Common pitfalls

> [!WARNING]
> Excluding a folder after its Application exists deletes that Application on the next read. A wide path such as `*` can match folders that are not environments. The matrix of two large generators creates many Applications at once. A repository that cannot be reached makes the generator fail, and the existing Applications stay as they are.
