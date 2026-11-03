#!/usr/bin/env bash
# Grades the classification: detection-record names the crashing, the not-ready and the healthy workload
# and the exit code, and each answer must match the live cluster.
set -u
fail() { echo "FAIL: $*"; exit 1; }

cm="$(kubectl -n starfleet get configmap detection-record -o json 2>/dev/null)" || fail "no ConfigMap detection-record in starfleet"
get() { jq -r --arg k "$1" '.data[$k] // ""' <<<"$cm"; }

[ "$(get crashing)" = "probe" ] || fail "key crashing must be probe (value: '$(get crashing)')"
[ "$(get not-ready)" = "beacon" ] || fail "key not-ready must be beacon (value: '$(get not-ready)')"
[ "$(get healthy)" = "scout" ] || fail "key healthy must be scout (value: '$(get healthy)')"

code="$(kubectl -n starfleet get pods -l app=probe -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}' 2>/dev/null)"
[ -n "$code" ] || fail "the probe pod has no terminated state yet; wait a moment and submit again"
[ "$(get exit-code)" = "$code" ] || fail "key exit-code is '$(get exit-code)', but the probe container exited with $code"

status="$(kubectl -n starfleet get pods -l app=beacon -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)"
[ "$status" = "false" ] || fail "the beacon pod is ready ($status); do not repair the workloads in this task"
echo "PASS: detection-record classifies probe, beacon and scout and the exit code $code"
