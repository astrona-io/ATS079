#!/usr/bin/env bash
# Grades the record: the ConfigMap incident-record names the cause, the mitigation and the final status.
set -u
fail() { echo "FAIL: $*"; exit 1; }

cm="$(kubectl -n starfleet get configmap incident-record -o json 2>/dev/null)" || fail "no ConfigMap incident-record in starfleet"
get() { jq -r --arg k "$1" '.data[$k] // ""' <<<"$cm"; }
[ -n "$(get severity)" ] || fail "key severity is missing or empty"
cause="$(get cause)"
grep -q '6\.15\.99' <<<"$cause" || fail "key cause must name the bad image tag 6.15.99 (value: '${cause:-empty}')"
[ "$(get mitigation)" = "rollback" ] || fail "key mitigation must be exactly rollback (value: '$(get mitigation)')"
[ "$(get status)" = "resolved" ] || fail "key status must be exactly resolved (value: '$(get status)')"
[ -n "$(get timeline)" ] || fail "key timeline is missing or empty"
echo "PASS: incident-record has severity, cause, mitigation rollback, status resolved and a timeline"
