#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/workflowtemplate-build-pipeline.yaml" <<'YAML'
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
YAML
cat > "$WORK/workflow-build-run-1.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: build-run-1
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: build-pipeline
YAML

kubectl apply -f "$WORK/workflowtemplate-build-pipeline.yaml"
kubectl create -f "$WORK/workflow-build-run-1.yaml"
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/build-run-1 --timeout=300s
