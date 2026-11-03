#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/workflowtemplate-ci-pipeline.yaml" <<'YAML'
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
YAML
cat > "$WORK/workflow-ci-run-1.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: ci-run-1
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: ci-pipeline
YAML

kubectl apply -f "$WORK/workflowtemplate-ci-pipeline.yaml"
kubectl create -f "$WORK/workflow-ci-run-1.yaml"
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded workflow/ci-run-1 --timeout=300s
