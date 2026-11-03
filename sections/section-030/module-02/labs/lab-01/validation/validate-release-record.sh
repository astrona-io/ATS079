#!/usr/bin/env bash
# Grades the release record ConfigMap.
set -u
fail() { echo "FAIL: $*"; exit 1; }

cm="$(kubectl -n starfleet get configmap release-record -o json 2>/dev/null)" || fail "no ConfigMap release-record in starfleet"
get() { jq -r --arg k "$1" '.data[$k] // ""' <<<"$cm"; }
[ "$(get strategy)" = "blue-green" ] || fail "key strategy must be exactly blue-green (value: '$(get strategy)')"
[ "$(get live)" = "green" ] || fail "key live must be exactly green (value: '$(get live)')"
[ "$(get previous)" = "blue" ] || fail "key previous must be exactly blue (value: '$(get previous)')"
rb="$(get rollback)"
grep -q 'kubectl' <<<"$rb" && grep -q 'blue' <<<"$rb" || fail "key rollback must hold the kubectl command that switches back to blue (value: '${rb:-empty}')"
echo "PASS: release-record has strategy, live, previous and the rollback command"
