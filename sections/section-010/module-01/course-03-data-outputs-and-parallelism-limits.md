---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# Data, Outputs And Parallelism Limits

Tasks in a pipeline pass data to each other. The build task produces a version string or a file, and the package task needs it. A graph that only orders the tasks does not move that data. The pipeline must also say which value goes where, and the two statements, the order and the data, must agree.

This part explains output parameters and artifacts, why a reference to an output needs a matching dependency, and how parallelism settings limit the number of tasks that run at once. It ends with a small pipeline that you run and inspect.

## Outputs

An **output parameter** is a small value, a string, that a task publishes when it finishes. The task writes the value to a file inside its container, and the template declares where the file is. The workflow controller reads the file after the container exits and stores the value in the workflow status.

```yaml
    - name: make-version
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo 1.4.2 > /tmp/version.txt"]
      outputs:
        parameters:
          - name: version
            valueFrom:
              path: /tmp/version.txt
```

The block `outputs.parameters` names the output `version` and says that its value is the content of `/tmp/version.txt`. A later task reads it with `{{tasks.<task name>.outputs.parameters.version}}`, where the task name is the name that the DAG gives to the task and not the name of the template.

An **artifact** is a file or a folder, for example a test report or a compiled binary, that moves through an artifact repository such as an object store. Artifacts suit data that is too large for a parameter. They need a configured artifact repository, so the playground in this module uses parameters only.

## A reference is not a dependency

A reference such as `{{tasks.build.outputs.parameters.version}}` says which value a task needs. The `depends` field says when the task may start. They answer different questions, and a correct pipeline states both.

The value of an output exists only after the producer finished. A task that uses it must therefore list the producer in `depends`. Without that line, the consumer can become eligible while the value does not exist yet, and the task fails or runs with an empty value. A reference does not create the output, and it does not make a task wait.

A skipped producer shows the second half of the problem. If the task `publish` is skipped by a `when` expression, it has no output, because no container ran. A task that refers to the output of `publish` gets no value to substitute. The consumer needs a condition that matches this case, for example a `when` that tests whether the producer ran, or a design in which the consumer does not use the output of an optional task.

## A pipeline with data

<!-- astrona:playground:renew -->
Save this as `workflowtemplate-versioned.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: versioned
  namespace: starfleet
spec:
  entrypoint: pipeline
  serviceAccountName: workflow-runner
  templates:
    - name: pipeline
      dag:
        tasks:
          - name: version
            template: make-version
          - name: package
            depends: version
            template: use-version
            arguments:
              parameters:
                - name: version
                  value: "{{tasks.version.outputs.parameters.version}}"
    - name: make-version
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo 1.4.2 > /tmp/version.txt"]
      outputs:
        parameters:
          - name: version
            valueFrom:
              path: /tmp/version.txt
    - name: use-version
      inputs:
        parameters:
          - name: version
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo packaging version {{inputs.parameters.version}}"]
```

The task `package` has both parts: the `depends: version` line orders it after the producer, and the argument takes the value of the output. Apply the template and start a run:

```sh
kubectl apply -f workflowtemplate-versioned.yaml
```

Save this as `workflow-versioned-run.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: versioned-run
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: versioned
```

Create the run, wait for it and read the log of the packaging pod:

```sh
kubectl create -f workflow-versioned-run.yaml
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/versioned-run --timeout=180s
kubectl -n starfleet logs -l workflows.argoproj.io/workflow=versioned-run -c main --tail=5
```

The label `workflows.argoproj.io/workflow` is set by the controller on every pod of the run. The `main` container is the one that runs your command, and the log of the packaging pod contains the line `packaging version 1.4.2`. The log of the other pod is empty because it only writes a file. You can also read the stored value from the status:

```sh
kubectl -n starfleet get workflow versioned-run -o json | jq -r '.status.nodes[] | select(.displayName=="version") | .outputs.parameters[] | [.name, .value] | @tsv'
```

## Limiting parallelism

A DAG with fifty independent tasks becomes fifty eligible tasks at the same moment. Fifty pods start together, and they compete for the CPU, the memory and the image pulls of the cluster. Parallelism settings put a ceiling on this.

The field `spec.parallelism` of a workflow limits how many pods the whole workflow runs at once. The field `parallelism` on a DAG template, written next to `tasks`, limits the number of children of that DAG that run at once. With `parallelism: 2`, the diamond from the first lesson still runs `lint` and `test` together, but a graph with five test shards runs two of them, and starts the next one when one finishes.

```yaml
spec:
  entrypoint: pipeline
  parallelism: 2
```

A parallelism limit does not change correctness. The order that `depends` defines is the same, and every task still runs after its dependencies. The limit changes only when eligible tasks get a pod. A pipeline that appears to be slow can show this: the tasks are waiting for a free slot under the limit, and not for a dependency.

There is a second limit that the workflow does not control. The cluster itself may have no room for another pod. A pod that the workflow controller created stays `Pending` until the scheduler finds a node. Use `kubectl describe pod` to read the scheduler events and tell the two cases apart.

## Running the same pipeline twice

CI pipelines run often. Two commits that arrive in a short time start two runs of the same template. If both write to the same target, for example a package with a fixed name, the second run can overwrite the first, or both can write in an unknown order. The pipeline must give each run its own identity, such as the commit hash in the artifact name, so a result can be traced to the source revision that produced it and the runs do not collide.

That identity is also what makes retries safe. If a task is run again with the same input and writes the same named result, the second run replaces the first with an equal value. A task that creates a new random name on every attempt leaves a trail of half-finished results.

This part showed how data moves between tasks and how concurrency is limited. Together with the dependency conditions, it gives a pipeline that has a clear order, a stated reaction to failure and a bounded use of the cluster. The question that is still open is which of these properties your own pipelines state explicitly and which they only assume.

## Common pitfalls

> [!WARNING]
> A reference to an output does not make a task wait for the producer, so keep `depends` and the reference together. A skipped task has no output to read. A parallelism limit delays eligible tasks but does not change the order. Parameters hold small strings, and large files belong in artifacts.
