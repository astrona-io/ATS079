#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/workflowtemplate-release-pipeline.yaml" <<'YAML'
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
YAML
cat > "$WORK/workflow-release-1.yaml" <<'YAML'
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
YAML
cat > "$WORK/workflow-release-2.yaml" <<'YAML'
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
YAML

kubectl apply -f "$WORK/workflowtemplate-release-pipeline.yaml"
kubectl create -f "$WORK/workflow-release-1.yaml"
kubectl create -f "$WORK/workflow-release-2.yaml"
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/release-1 --timeout=420s
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/release-2 --timeout=420s
