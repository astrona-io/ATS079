# Solution

The pipeline combines four mechanisms: a DAG with parallel branches, an output that is passed on with a matching dependency, a retry for a temporary failure and a condition that skips a task. The workflow controller starts the pods, and the setting `parallelism: 2` limits how many it runs at once.

## Step 1: save the WorkflowTemplate

The task `version` runs next to the checks because it only needs `checkout`. The task `package` lists `version` in `depends` and uses the output in an argument, so the order and the data agree. The template `integration-step` has a `retryStrategy`: `{{retries}}` is `0` in the first pod, so `test 0 -ge 1` fails, and it is `1` in the retry pod, so the command succeeds.

Save this as `workflowtemplate-release-pipeline.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: release-pipeline
  namespace: starfleet
spec:
  entrypoint: pipeline
  serviceAccountName: workflow-runner
  parallelism: 2
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
          - name: version
            depends: checkout
            template: make-version
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
          - name: scan
            depends: checkout
            template: step
            arguments:
              parameters:
                - name: command
                  value: "echo scan; sleep 10"
          - name: integration
            depends: test
            template: integration-step
          - name: package
            depends: lint && scan && integration && version
            template: package-step
            arguments:
              parameters:
                - name: version
                  value: "{{tasks.version.outputs.parameters.version}}"
          - name: publish
            depends: package
            when: "{{workflow.parameters.publish}} == true"
            template: step
            arguments:
              parameters:
                - name: command
                  value: "echo publish"
          - name: notify
            depends: package.Completed || lint.Failed || test.Failed || scan.Failed || integration.Failed
            template: step
            arguments:
              parameters:
                - name: command
                  value: "echo notify"
    - name: step
      inputs:
        parameters:
          - name: command
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["{{inputs.parameters.command}}"]
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
    - name: integration-step
      retryStrategy:
        limit: 2
        retryPolicy: OnFailure
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["test {{retries}} -ge 1"]
    - name: package-step
      inputs:
        parameters:
          - name: version
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo packaging version {{inputs.parameters.version}}"]
```

Apply it:

```sh
kubectl apply -f workflowtemplate-release-pipeline.yaml
```

## Step 2: start the two runs

Both runs use the same template. The first one overrides the parameter `publish`, and the second one uses the default.

Save this as `workflow-release-1.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: release-1
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: release-pipeline
  arguments:
    parameters:
      - name: publish
        value: "true"
```

Save this as `workflow-release-2.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: release-2
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: release-pipeline
  arguments:
    parameters:
      - name: publish
        value: "false"
```

Create both and wait for them:

```sh
kubectl create -f workflow-release-1.yaml
kubectl create -f workflow-release-2.yaml
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/release-1 workflow/release-2 --timeout=300s
```

## Step 3: check the evidence

List the attempts of `integration` and the phase of `publish` in both runs:

```sh
kubectl -n starfleet get workflow release-1 -o json | jq -r '.status.nodes[] | select(.displayName | startswith("integration")) | [.displayName, .type, .phase] | @tsv'
kubectl -n starfleet get workflow release-2 -o json | jq -r '.status.nodes[] | select(.displayName=="publish") | [.displayName, .phase] | @tsv'
```

The first command shows a retry node and two attempts: the first is `Failed` and the second is `Succeeded`. The second command shows `Skipped`.

Check your work with `astrona submit`.
