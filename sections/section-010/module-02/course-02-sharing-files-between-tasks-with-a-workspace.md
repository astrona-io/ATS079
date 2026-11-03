---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# Sharing Files Between Tasks With A Workspace

Every task in Argo Workflows runs in its own pod, and a pod has its own file system. A build task that writes a compiled program to its disk leaves nothing for the package task, because the build pod is gone when the package pod starts. A pipeline therefore needs a place where tasks leave files for each other.

This part shows the workspace pattern, which gives all tasks of one workflow a shared volume, and the output parameter, which passes a small value such as a version. It also explains when each one is the right choice.

## Two ways to pass data

A **parameter** is a short string. It travels in the workflow object itself, so it must stay small: Argo Workflows limits the total size of a workflow object, and a large value breaks the workflow. Use a parameter for a version number, an image reference or a commit hash.

A **workspace** is a PersistentVolumeClaim (PVC), a request for storage in Kubernetes, that every task mounts. Tasks read and write files on it like on a normal disk. Use a workspace for source code, build output and test reports.

A third way, the artifact, copies files to an object store such as S3. It needs an artifact repository that the cluster must provide, so this playground does not use it. The workspace pattern gives the same result inside one workflow without extra infrastructure.

## A workspace for one workflow

The field `volumeClaimTemplates` on a workflow creates a PVC when the run starts and deletes it when the run ends. Each run gets its own volume, so two runs never overwrite each other's files.

<!-- astrona:playground:renew -->
Save this as `workflowtemplate-workspace.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: workspace
  namespace: starfleet
spec:
  entrypoint: pipeline
  serviceAccountName: workflow-runner
  volumeClaimTemplates:
    - metadata:
        name: work
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 64Mi
  templates:
    - name: pipeline
      dag:
        tasks:
          - name: build
            template: build
          - name: package
            depends: build
            template: package
    - name: build
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo compiled-program > /work/app.bin"]
        volumeMounts:
          - name: work
            mountPath: /work
    - name: package
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["cat /work/app.bin"]
        volumeMounts:
          - name: work
            mountPath: /work
```

Apply it:

```sh
kubectl apply -f workflowtemplate-workspace.yaml
```

Save this as `workflow-workspace-run.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: workspace-run
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: workspace
```

Create the run, wait for it and read the log of the package pod:

```sh
kubectl create -f workflow-workspace-run.yaml
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/workspace-run --timeout=180s
kubectl -n starfleet logs -l workflows.argoproj.io/workflow=workspace-run -c main --tail=5
```

The log lines of both pods show the text `compiled-program`, because the build pod wrote it and the package pod read it from the same volume. Without `volumeMounts` in both templates, the second pod would find no file.

The access mode `ReadWriteOnce` lets pods on one node use the volume at the same time. Parallel tasks on different nodes would need a storage class that supports `ReadWriteMany`. On the single-node playground cluster this limit does not show.

## Passing a value as an output parameter

A task can write a short value to a file and publish it as an output parameter. A later task reads it with `{{tasks.<name>.outputs.parameters.<output>}}`. The consumer must also list the producer in `depends`, because the reference alone does not make it wait.

```yaml
    - name: version
      outputs:
        parameters:
          - name: version
            valueFrom:
              path: /tmp/version.txt
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo 1.4.0 > /tmp/version.txt"]
```

The field `valueFrom.path` names the file inside the container that holds the value. The controller reads the file after the pod finishes and stores the value in the workflow status. A package task then uses the value in its own arguments.

## Choosing between them

Use a parameter when the value is short and the next task needs to know it to decide what to do, for example which image tag to build. Use the workspace when the next task needs the contents of files. Many pipelines use both: a workspace for the build output and a parameter for the final image reference.

The workspace also holds a risk. Tasks that run in parallel and write to the same path overwrite each other. Give each parallel task its own directory on the volume.

The pipeline can now pass files and values. The remaining question is what the final value, the image reference, should look like so that nobody deploys the wrong build.

## Common pitfalls

> [!WARNING]
> A file written outside a mounted volume disappears with its pod. A large value in a parameter can exceed the size limit of the workflow object. An output parameter reference without the matching `depends` entry can run before the value exists. Two parallel tasks that write the same path on a shared volume corrupt each other's output.
