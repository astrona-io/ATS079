#!/usr/bin/env bash
# Grades conditional behaviour: publish skipped, report ran.
set -u
fail() { echo "FAIL: $*"; exit 1; }

wf="$(kubectl -n starfleet get workflow ci-run-1 -o json 2>/dev/null)" || fail "no Workflow ci-run-1 in starfleet"
phase_of() { jq -r --arg n "$1" '[.status.nodes[] | select(.displayName==$n)][0].phase // "missing"' <<<"$wf"; }

[ "$(phase_of publish)" = "Skipped" ] || fail "publish phase is '$(phase_of publish)', expected Skipped"
[ "$(phase_of report)" = "Succeeded" ] || fail "report phase is '$(phase_of report)', expected Succeeded"
[ "$(phase_of package)" = "Succeeded" ] || fail "package phase is '$(phase_of package)', expected Succeeded"
echo "PASS: publish was skipped by its when expression and report ran"
