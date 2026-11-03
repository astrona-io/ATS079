---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# CI, Continuous Delivery And Continuous Deployment

The abbreviation CI/CD hides three different practices, and mixing them up causes real design mistakes. This part defines each practice by what it produces and what it needs, introduces the artifact as the object that connects them, and then looks at a running delivery in the playground before anything is changed.

## Three practices

**Continuous integration** is the practice of merging changes into a shared branch often, and of running an automated build and checks on every change. Its output is a verdict, pass or fail, and for a passing change, an artifact: a container image, a package or a chart. CI does not need to know where the artifact will run.

**Continuous delivery** is the practice of keeping every passing change in a state where it can be released to an environment at any time. The release itself is a decision, made by a person or by a rule, for example a promotion from staging to production. Its output is a change in the desired state of an environment.

**Continuous deployment** goes one step further: every change that passes the checks is released to production without a person in between. It is not a better version of continuous delivery. It is a different policy, and it needs checks that are good enough to replace the person, and a way to go back quickly.

The three share one rule: the thing that was tested must be the thing that is deployed. That rule needs an artifact that does not change after the build.

## The artifact is the contract

A container image is identified in two ways. A **tag**, such as `6.15.0`, is a name that the registry can move to point at another image. A **digest**, such as `sha256:...`, is the hash of the image content and cannot point at anything else. A tag is convenient for people. A digest is what proves that the bytes are the same.

If CI tests an image and a later step deploys the tag, a change of the tag in between would deploy something that was never tested. Pinning to a digest removes that gap. When tags are used, the team must have a rule that a released tag is never moved.

**Provenance** is the record of where an artifact came from: which source commit, which build and which builder. It is what lets an operator go from a running pod to the change that created it. Without it, the answer to the question which commit is running in production is a guess.

```mermaid
flowchart LR
    C["Commit"] --> B["CI build and checks"]
    B --> A["Artifact: image with tag or digest"]
    B --> G["Change in Git: new image reference"]
    G --> D["Argo CD reads Git"]
    D --> K["Cluster runs the artifact"]
```

The diagram has two outputs from the build. The artifact goes to a registry, and the new reference goes to Git. The cluster is changed by Argo CD, which reads Git, and not by the CI system.

## Where the release decision lives

In continuous delivery, a person or a rule decides when an environment gets a new version. The decision has to be written somewhere that the delivery tool reads. Three places are common.

- A change in a Git repository, merged by a person after review. The history of the repository is then the history of the decisions, with an author and a time for each one.
- A command or a button in the delivery tool. This is quick, but the decision is stored only in the tool, and a second tool may not see it.
- A rule in the pipeline, such as promote to production when staging has been healthy for an hour. The rule is code, so it can be reviewed, but its result must still be written to Git, or the environment has no record.

This module uses the first place. A decision that is a commit can be reviewed before it is merged, it can be reverted after, and it is visible to every tool that reads the repository.

## Why the delivery contract is small

The contract between CI and CD has two parts: an artifact reference and a record of the desired state in Git. CI needs permission to push the artifact to a registry and permission to write to one Git repository. It does not need any credential for the cluster. Argo CD needs permission to read Git and to change the namespaces that it manages. It does not need the right to build anything.

This split limits the damage of a stolen credential. A compromised CI job can propose a bad change in Git, which is visible in the history and can be reverted. It cannot reach into the cluster directly. The next part shows the change that CI makes.

<!-- astrona:playground:renew -->
## Try it: read a delivery that already happened

The playground starts with a delivered staging environment. Git holds the desired state, the Application `scout-staging` in Argo CD connects Git to the cluster, and a Deployment `scout` runs in the namespace `starfleet-staging`. Read the three layers from the bottom to the top.

First, which version runs in the cluster:

```sh
kubectl -n starfleet-staging get deploy scout -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

The image ends with `6.14.0`. Next, what Argo CD says about it:

```sh
kubectl -n argocd get application scout-staging
kubectl -n argocd get application scout-staging -o jsonpath='{.status.sync.revision}{"\n"}'
```

The first command shows the sync status `Synced` and the health status `Healthy`. The second prints a Git commit ID, the revision of the repository that Argo CD compared with the cluster. Last, what Git says. The Git server in the cluster is reachable from your machine on port 3000, with the user `platform` and the password `starfleet-gitops`:

```sh
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git
cd scout-deploy
git log --oneline
grep -n newTag overlays/staging/kustomization.yaml
```

The log has one commit, and its ID begins with the same characters as the revision that Argo CD printed. The file `overlays/staging/kustomization.yaml` contains the line `newTag: 6.14.0`. This chain, from a line in Git to the revision in the Application to the image in the Deployment, is what makes a delivery observable. If one link is missing, the question which commit is running cannot be answered with certainty.

## What an unobservable delivery looks like

If the cluster were changed by `kubectl apply` from a CI job, the Deployment would still run an image, but Git would not say which. The Application would show `OutOfSync` or would not exist, and the history would show nothing. The version in production would be known only to the job log. A delivery contract is observable when every step leaves a record that can be read later by someone who was not there.

This part defined the three practices and the artifact. The next part makes the contract concrete: a promotion is a commit, and Argo CD turns it into a change in the cluster.

## Common pitfalls

> [!WARNING]
> Continuous delivery and continuous deployment are not the same: delivery keeps a release decision, deployment removes it. A tag can be moved to a different image, so a tested tag is not proof of a tested image unless tags are never reused. A CI job that needs cluster credentials to deliver has taken over the job of the delivery tool, and a leak of that job then reaches the cluster.
