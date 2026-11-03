#!/usr/bin/env bash
# Grades the hand-off: deliver received the image reference from package and the workspace carried a file.
set -u
fail() { echo "FAIL: $*"; exit 1; }

wf="$(kubectl -n starfleet get workflow build-run-1 -o json 2>/dev/null)" || fail "no Workflow build-run-1 in starfleet"
got="$(jq -r '[.status.nodes[]? | select(.displayName=="deliver") | .inputs.parameters[]? | .value] | first // ""' <<<"$wf")"
[ "$got" = "scout:1.4.0-3f9c2ab" ] || fail "deliver received '$got', expected scout:1.4.0-3f9c2ab through an input parameter"
for t in build package deliver; do
  p="$(jq -r "[.status.nodes[]? | select(.displayName==\"$t\") | .phase] | first // \"\"" <<<"$wf")"
  [ "$p" = "Succeeded" ] || fail "task $t has the phase '${p:-none}', expected Succeeded"
done
pkg_log="$(kubectl -n starfleet logs -l workflows.argoproj.io/workflow=build-run-1 -c main --tail=20 --prefix=false 2>/dev/null || true)"
grep -q "app.bin" <<<"$pkg_log" || fail "no task log shows the file app.bin from the shared workspace"
echo "PASS: deliver received the reference and the workspace carried app.bin"
