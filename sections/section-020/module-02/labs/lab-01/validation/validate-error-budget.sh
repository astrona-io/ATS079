#!/usr/bin/env bash
# Grades the error budget calculation and the severity entry in detection-record.
set -u
fail() { echo "FAIL: $*"; exit 1; }

cm="$(kubectl -n starfleet get configmap detection-record -o json 2>/dev/null)" || fail "no ConfigMap detection-record in starfleet"
get() { jq -r --arg k "$1" '.data[$k] // ""' <<<"$cm"; }

[ "$(get error-budget-minutes)" = "43.2" ] || fail "key error-budget-minutes must be 43.2 for an objective of 99.9 percent over 30 days (value: '$(get error-budget-minutes)')"
[ -n "$(get severity)" ] || fail "key severity is missing or empty"
[ -n "$(get signal)" ] || fail "key signal is missing or empty"
echo "PASS: error-budget-minutes is 43.2 and severity and signal are set"
