# Solution

The task has three parts: describe the pipeline in a `WorkflowTemplate`, start one run from it and check the output parameter in the workflow status. The build and package tasks share files through a volume that the workflow creates, and the package task hands the image reference to the deliver task through an output parameter.

## Step 1: save the WorkflowTemplate

The field `volumeClaimTemplates` creates the volume `work` for each run. The `build` task writes `app.bin` to it, and `package` reads the file from the same volume. The package task writes the image reference to `/tmp/image.txt`, and `outputs.parameters` with `valueFrom.path` turns the file content into the output parameter `image`. The `deliver` task reads it with `{{tasks.package.outputs.parameters.image}}` and also depends on `package`, so it waits.

Save this as `workflowtemplate-build-pipeline.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: build-pipeline
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
          - name: deliver
            depends: package
            template: deliver
            arguments:
              parameters:
                - name: image
                  value: "{{tasks.package.outputs.parameters.image}}"
    - name: build
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo compiled-program > /work/app.bin; echo built app.bin"]
        volumeMounts:
          - name: work
            mountPath: /work
    - name: package
      outputs:
        parameters:
          - name: image
            valueFrom:
              path: /tmp/image.txt
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["cat /work/app.bin; echo scout:{{workflow.parameters.version}}-{{workflow.parameters.commit}} > /tmp/image.txt"]
        volumeMounts:
          - name: work
            mountPath: /work
    - name: deliver
      inputs:
        parameters:
          - name: image
      container:
        image: alpine:3.23
        command: [sh, -c]
        args: ["echo deliver {{inputs.parameters.image}}"]
```

Apply it:

```sh
kubectl apply -f workflowtemplate-build-pipeline.yaml
```

## Step 2: run it once

Save this as `workflow-build-run-1.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: build-run-1
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: build-pipeline
```

Create it and wait for it to finish:

```sh
kubectl create -f workflow-build-run-1.yaml
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/build-run-1 --timeout=300s
```

## Step 3: read the image reference

Print the output parameter of the package task and the input of the deliver task:

```sh
kubectl -n starfleet get workflow build-run-1 -o json | jq -r '.status.nodes[] | select(.displayName=="package") | .outputs.parameters[0].value'
kubectl -n starfleet get workflow build-run-1 -o json | jq -r '.status.nodes[] | select(.displayName=="deliver") | .inputs.parameters[0].value'
```

Both commands print `scout:1.4.0-3f9c2ab`. Run `astrona submit` to grade the result.
