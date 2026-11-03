#!/usr/bin/env bash
# Grades the two runs: both use the template with the right parameter and Succeeded.
set -u
fail() { echo "FAIL: $*"; exit 1; }

for pair in "release-1:true" "release-2:false"; do
  name="${pair%%:*}"; want="${pair##*:}"
  wf="$(kubectl -n starfleet get workflow "$name" -o json 2>/dev/null)" || fail "no Workflow $name in starfleet"
  [ "$(jq -r '.spec.workflowTemplateRef.name // ""' <<<"$wf")" = "release-pipeline" ] || fail "$name does not use the template release-pipeline"
  got="$(jq -r '.spec.arguments.parameters[]? | select(.name=="publish") | .value' <<<"$wf")"
  [ "$name" = "release-2" ] && [ -z "$got" ] && got="false"
  [ "$got" = "$want" ] || fail "$name has publish='$got', expected '$want'"
  phase="$(jq -r '.status.phase // ""' <<<"$wf")"
  [ "$phase" = "Succeeded" ] || fail "$name phase is '${phase:-unknown}', expected Succeeded"
done
echo "PASS: release-1 and release-2 used the template and Succeeded"
