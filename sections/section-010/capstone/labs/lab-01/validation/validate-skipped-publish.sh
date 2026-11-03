#!/usr/bin/env bash
# Grades release-2: publish skipped by its when expression, package succeeded.
set -u
fail() { echo "FAIL: $*"; exit 1; }

wf="$(kubectl -n starfleet get workflow release-2 -o json 2>/dev/null)" || fail "no Workflow release-2 in starfleet"
phase_of() { jq -r --arg n "$1" '[.status.nodes[] | select(.displayName==$n)][0].phase // "missing"' <<<"$wf"; }
[ "$(phase_of publish)" = "Skipped" ] || fail "publish phase in release-2 is '$(phase_of publish)', expected Skipped"
[ "$(phase_of package)" = "Succeeded" ] || fail "package phase in release-2 is '$(phase_of package)', expected Succeeded"
echo "PASS: publish was skipped in release-2"
