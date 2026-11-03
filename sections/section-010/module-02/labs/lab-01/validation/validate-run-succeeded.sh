#!/usr/bin/env bash
# Grades the run: build-run-1 exists, uses the template and finished with Succeeded.
set -u
fail() { echo "FAIL: $*"; exit 1; }

wf="$(kubectl -n starfleet get workflow build-run-1 -o json 2>/dev/null)" || fail "no Workflow build-run-1 in starfleet"
ref="$(jq -r '.spec.workflowTemplateRef.name // ""' <<<"$wf")"
[ "$ref" = "build-pipeline" ] || fail "build-run-1 does not use the template build-pipeline (workflowTemplateRef is '$ref')"
phase="$(jq -r '.status.phase // ""' <<<"$wf")"
[ "$phase" = "Succeeded" ] || fail "build-run-1 phase is '${phase:-unknown}', expected Succeeded"
echo "PASS: build-run-1 used build-pipeline and Succeeded"
