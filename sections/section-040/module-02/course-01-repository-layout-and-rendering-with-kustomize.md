---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Repository Layout And Rendering With Kustomize

In GitOps the repository is the source of truth, so its structure decides how easy it is to answer simple questions: what runs in production, who changed it and how a change moves from staging to production. A messy layout makes every one of those questions slow, and slow answers cost time during an incident.

This part describes the layout of the example repository, explains the choice between one repository and several, and shows how Kustomize renders the files that Argo CD applies.

## Application code and configuration

Two kinds of files exist for an application. The **application repository** holds the source code and the build files. The **configuration repository** holds the Kubernetes manifests that describe how the application runs. GitOps tools watch the configuration repository.

Keeping them apart has reasons. A commit to the code repository starts a CI pipeline, and the pipeline would start again if it pushed its own version bump into the same repository. The configuration repository can also have stricter rules: only the delivery process and a few people may change production. The cost is one more repository and a step in the pipeline that updates the image tag in the configuration repository.

## Folder structure

The example repository `scout-deploy` uses a base and overlays.

- `base/` holds manifests that are the same in every environment: the Deployment, the Service and a `kustomization.yaml` that lists them.
- `overlays/staging/` and `overlays/production/` each hold a `kustomization.yaml` that points at the base and changes what differs: the namespace, the image tag, the replica count and an environment variable.

**Kustomize** is a tool, built into `kubectl`, that builds the final manifests from a base and patches. It does not use templates. The base stays valid YAML, and an overlay states changes on top of it. Argo CD runs Kustomize when it finds a `kustomization.yaml` in the path of an Application.

## One repository or several

- A **single repository** with a folder per environment is easy to start with. A change to staging and production can be one commit, and one search finds everything. The risk is that anyone with write access can change production, unless branch rules or code owners limit it.
- **One repository per environment** gives clean access control and a separate history for production. The cost is that a promotion is a change in a second repository.
- **One repository per team** limits the blast radius of a mistake and fits a platform where teams own their applications.

There is no single right answer. Choose by who must be allowed to change what, and write the choice down.

## Render before you push

The command `kubectl kustomize` prints the manifests that Kustomize builds, without touching the cluster. It shows what Argo CD will see.

<!-- astrona:playground:renew -->
Clone the repository, which is reachable from your machine on port 3000:

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
```

Render the staging overlay:

```sh
kubectl kustomize overlays/staging
```

The output is the Service and the Deployment with the namespace `starfleet-staging`, the label `environment: staging`, the image `ghcr.io/stefanprodan/podinfo:6.14.0` and the environment variable that the patch adds. Render the production overlay the same way and compare the two outputs:

```sh
diff <(kubectl kustomize overlays/staging) <(kubectl kustomize overlays/production)
```

The differences are exactly the settings that the overlays change. A reviewer can run the same command on a pull request to see the effect of a change before it is merged.

## Helm in the same model

A Helm chart is another way to render manifests. It packages templates and a `values.yaml` file with the settings. Argo CD can render a chart from a Git path or from a chart repository, and per-environment values files take the place of overlays. The principle is the same: the repository holds the inputs, a tool renders them and Argo CD applies the result. Pin the chart version, as you pin an image tag.

## What the structure buys

A clear layout lets a reviewer see a production change as one diff, lets a pipeline update one line, and lets Argo CD compare the same path every time. The structure shown so far is only the input. The next part looks at the order in which Argo CD applies it.

## Common pitfalls

> [!WARNING]
> A pipeline that pushes to the same repository that triggers it can loop. A base that contains environment-specific values forces every overlay to undo them. Unpinned chart versions change what is rendered without a commit. Rendering on your machine with a different Kustomize version than Argo CD can produce a different result.
