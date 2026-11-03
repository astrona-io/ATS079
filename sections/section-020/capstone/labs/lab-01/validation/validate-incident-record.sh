#!/usr/bin/env bash
# Grades the record: one cause per service, with the key word of its fault class, and the final status.
set -u
fail() { echo "FAIL: $*"; exit 1; }

cm="$(kubectl -n starfleet get configmap incident-record -o json 2>/dev/null)" || fail "no ConfigMap incident-record in starfleet"
get() { jq -r --arg k "$1" '.data[$k] // ""' <<<"$cm"; }
[ -n "$(get severity)" ] || fail "key severity is missing or empty"
[ "$(get status)" = "resolved" ] || fail "key status must be exactly resolved (value: '$(get status)')"
[ -n "$(get timeline)" ] || fail "key timeline is missing or empty"
grep -qi 'image' <<<"$(get scout)" || fail "key scout must be a sentence that contains the word image"
grep -q 'ConfigMap' <<<"$(get probe)" || fail "key probe must be a sentence that contains the word ConfigMap"
grep -qi 'readiness' <<<"$(get bridge)" || fail "key bridge must be a sentence that contains the word readiness"
echo "PASS: incident-record names a cause for scout, probe and bridge, with status resolved"
