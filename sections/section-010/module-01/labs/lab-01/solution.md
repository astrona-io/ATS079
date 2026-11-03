# Solution

The task has three parts: describe the graph in a `WorkflowTemplate`, start one run from it and check the timing in the workflow status. Argo Workflows creates one pod per task, and its workflow controller starts a task when its `depends` condition is true.

## Step 1: save the WorkflowTemplate

The DAG template `pipeline` lists the six tasks. `lint` and `test` have the same dependency, `checkout`, so the controller starts both when `checkout` succeeded. `package` waits for both with `&&`. The task `report` uses the results `Completed` and `Failed`, because the default condition would not start it after a failure.

Save this as `workflowtemplate-ci-pipeline.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: ci-pipeline
  namespace: starfleet
spec:
  entrypoint: pipeline
  serviceAccountName: workflow-runner
  arguments:
    parameters:
      - name: publish
        value: "false"
  templates:
    - name: pipeline
      dag:
        tasks:
          - name: checkout
            template: step
            arguments:
              parameters:
                - name: command
                  value: "echo checkout"
          - name: lint
            depends: checkout
            template: step
            arguments:
              parameters:
                - name: command
                  value: "echo lint; sleep 10"
          - name: test
            depends: checkout
            template: step
            arguments:
              parameters:
                - name: command
                  value: "echo test; sleep 10"
          - name: package
            depends: lint && test
            template: step
            arguments:
              parameters:
                - name: command
                  value: "echo package"
          - name: publish
            depends: package
            when: "{{workflow.parameters.publish}} == true"
            template: step
            arguments:
              parameters:
                - name: command
                  value: "echo publish"
          - name: report
            depends: package.Completed || lint.Failed || test.Failed
            template: step
            arguments:
              parameters:
                - name: command
                  value: "echo report"
    - name: step
      inputs:
        parameters:
          - name: command
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["{{inputs.parameters.command}}"]
```

Apply it:

```sh
kubectl apply -f workflowtemplate-ci-pipeline.yaml
```

## Step 2: start a run

A `WorkflowTemplate` does not run by itself. A `Workflow` with a `workflowTemplateRef` starts one run and uses the default parameter values.

Save this as `workflow-ci-run-1.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: ci-run-1
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: ci-pipeline
```

Create it and wait for the result:

```sh
kubectl create -f workflow-ci-run-1.yaml
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/ci-run-1 --timeout=240s
```

## Step 3: check the timing

Print the phase and the times of each task:

```sh
kubectl -n starfleet get workflow ci-run-1 -o json | jq -r '.status.nodes[] | select(.type=="Pod" or .type=="Skipped") | [.displayName, .phase, .startedAt, .finishedAt] | @tsv'
```

The start times of `lint` and `test` are close together and both are earlier than the finish time of the other. `package` starts after both. `publish` shows `Skipped` because `false == true` is false, and `report` shows `Succeeded`.

Check your work with `astrona submit`.
