---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# Image Tags, Digests And Artifact Identity

The package stage creates a container image and gives it a name. That name is how every later step finds the build: the delivery step, the people who review a release and the incident responder who must know which code runs in production. If the name does not point to exactly one build, all of them can be wrong.

This part explains the two ways to name an image, the tag and the digest, shows why only one of them is stable, and gives the rules a pipeline should follow when it names an artifact.

## What an image reference is made of

An image reference has up to four parts: a registry host, a repository path, a tag and a digest. In `ghcr.io/stefanprodan/podinfo:6.15.0`, the registry is `ghcr.io`, the repository is `stefanprodan/podinfo` and the tag is `6.15.0`.

A **tag** is a label that the registry stores next to an image. The owner of the repository can move a tag to a different image at any time. The tag `latest` is only a convention for the newest build, and it moves with every push.

A **digest** is a SHA-256 hash of the image manifest, the file that lists the layers of the image. A digest looks like `sha256:` followed by 64 hexadecimal characters. Because it is calculated from the content, a different image always has a different digest, and the same digest always means the same bytes. A reference with a digest is written `repository@sha256:<digest>`.

## Why a tag alone is not enough

A pipeline pushes `scout:1.4.0` on Monday. On Tuesday somebody fixes a typo and pushes `scout:1.4.0` again. The tag now points to a different image. A node that pulled the image on Monday runs the old build, and a node that pulls it on Tuesday runs the new build. Both claim to run `1.4.0`.

This breaks three things. Two pods of one Deployment can run different code. A rollback to `1.4.0` can bring back a different build than the one that ran before. A review of what was deployed cannot be trusted. Setting the Kubernetes field `imagePullPolicy` does not fix this, because the policy only decides when to pull, not which image the tag means.

## Rules for naming an artifact

The pipeline can avoid the problem with a few rules.

1. **Build once per commit.** Build the image one time for a commit and promote that same image through every environment. Never rebuild for production.
2. **Tag with something unique.** Use the Git commit hash, a build number or a semantic version that the pipeline refuses to reuse. A tag such as `1.4.0-3f9c2ab` says which version and which commit.
3. **Record the digest.** The registry returns the digest after a push. The pipeline stores it as an output and passes it to the delivery step, so delivery refers to `scout@sha256:...`.
4. **Make tags immutable in the registry.** Many registries have a setting that rejects a push to an existing tag. Turn it on.

<!-- astrona:playground:renew -->
## Producing the reference in a workflow

The package task below builds the image reference from two workflow parameters and writes it as an output. It does not push an image, because the playground has no registry. It shows how the reference moves through the pipeline. Save this as `workflowtemplate-image-ref.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: image-ref
  namespace: starfleet
spec:
  entrypoint: pipeline
  serviceAccountName: workflow-runner
  arguments:
    parameters:
      - name: version
        value: "1.4.0"
      - name: commit
        value: "3f9c2ab"
  templates:
    - name: pipeline
      dag:
        tasks:
          - name: package
            template: package
          - name: deliver
            depends: package
            template: deliver
            arguments:
              parameters:
                - name: image
                  value: "{{tasks.package.outputs.parameters.image}}"
    - name: package
      outputs:
        parameters:
          - name: image
            valueFrom:
              path: /tmp/image.txt
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo scout:{{workflow.parameters.version}}-{{workflow.parameters.commit}} > /tmp/image.txt"]
    - name: deliver
      inputs:
        parameters:
          - name: image
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo would deliver {{inputs.parameters.image}}"]
```

Apply it:

```sh
kubectl apply -f workflowtemplate-image-ref.yaml
```

Save this as `workflow-image-ref-run.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: image-ref-run
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: image-ref
```

Create the run and print the output parameter of the package task:

```sh
kubectl create -f workflow-image-ref-run.yaml
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/image-ref-run --timeout=180s
kubectl -n starfleet get workflow image-ref-run -o json | jq -r '.status.nodes[] | select(.displayName=="package") | .outputs.parameters[0].value'
```

The last command prints `scout:1.4.0-3f9c2ab`. The `deliver` task received exactly this value through its input, so what the pipeline tested and what delivery uses cannot drift apart. In a real pipeline the value would end in `@sha256:` and the digest that the registry returned.

## Digests in the deployment

When the delivery uses the digest, the container runtime pulls by content. The registry cannot answer with a different image, even if someone moved a tag. A manifest can keep the readable tag for people and add the digest for machines, for example `scout:1.4.0@sha256:<digest>`. The runtime then verifies the digest, and the tag only documents the intent.

A pipeline that records tag, commit and digest for every build can answer the question "what code runs in production" from one record. The next part looks at how to make the build itself produce the same output for the same input.

## Common pitfalls

> [!WARNING]
> Tags such as `latest` or a reused version move, so they cannot identify a build. A rebuild for each environment produces different images that were never tested together. Tag immutability must be enabled in the registry, not only agreed in a document. A digest taken before a push is not valid, because the registry calculates the final manifest.
