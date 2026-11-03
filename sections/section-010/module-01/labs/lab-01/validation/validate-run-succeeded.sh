#!/usr/bin/env bash
# Grades the run: ci-run-1 exists, uses the template and finished with Succeeded.
set -u
fail() { echo "FAIL: $*"; exit 1; }

wf="$(kubectl -n starfleet get workflow ci-run-1 -o json 2>/dev/null)" || fail "no Workflow ci-run-1 in starfleet"
ref="$(jq -r '.spec.workflowTemplateRef.name // ""' <<<"$wf")"
[ "$ref" = "ci-pipeline" ] || fail "ci-run-1 does not use the template ci-pipeline (workflowTemplateRef is '$ref')"
phase="$(jq -r '.status.phase // ""' <<<"$wf")"
[ "$phase" = "Succeeded" ] || fail "ci-run-1 phase is '${phase:-unknown}', expected Succeeded"
echo "PASS: ci-run-1 used ci-pipeline and Succeeded"
