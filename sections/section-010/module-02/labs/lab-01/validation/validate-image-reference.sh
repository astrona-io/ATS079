#!/usr/bin/env bash
# Grades the artifact identity: the package task published the image reference as an output parameter.
set -u
fail() { echo "FAIL: $*"; exit 1; }

wf="$(kubectl -n starfleet get workflow build-run-1 -o json 2>/dev/null)" || fail "no Workflow build-run-1 in starfleet"
image="$(jq -r '[.status.nodes[]? | select(.displayName=="package") | .outputs.parameters[]? | select(.name=="image") | .value] | first // ""' <<<"$wf")"
[ -n "$image" ] || fail "the package task has no output parameter image"
[ "$image" = "scout:1.4.0-3f9c2ab" ] || fail "the image output is '$image', expected scout:1.4.0-3f9c2ab"
echo "PASS: package published scout:1.4.0-3f9c2ab"
