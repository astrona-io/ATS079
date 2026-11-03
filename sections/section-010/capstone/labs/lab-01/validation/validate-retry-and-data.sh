#!/usr/bin/env bash
# Grades release-1: integration retried, package got the version, publish ran.
set -u
fail() { echo "FAIL: $*"; exit 1; }

wf="$(kubectl -n starfleet get workflow release-1 -o json 2>/dev/null)" || fail "no Workflow release-1 in starfleet"

attempts="$(jq '[.status.nodes[] | select(.type=="Pod" and (.displayName | startswith("integration(")))] | length' <<<"$wf")"
[ "$attempts" -ge 2 ] || fail "integration has $attempts attempt(s), expected at least 2 (first fails, retry succeeds)"
first="$(jq -r '[.status.nodes[] | select(.type=="Pod" and (.displayName | startswith("integration(")))] | sort_by(.startedAt) | .[0].phase' <<<"$wf")"
last="$(jq -r '[.status.nodes[] | select(.type=="Pod" and (.displayName | startswith("integration(")))] | sort_by(.startedAt) | .[-1].phase' <<<"$wf")"
[ "$first" = "Failed" ] || fail "the first attempt of integration is '$first', expected Failed"
[ "$last" = "Succeeded" ] || fail "the last attempt of integration is '$last', expected Succeeded"

version="$(jq -r '[.status.nodes[] | select(.displayName=="package")][0].inputs.parameters[]? | select(.name=="version") | .value' <<<"$wf")"
[ "$version" = "1.4.2" ] || fail "package received version '${version:-nothing}', expected 1.4.2"

pub="$(jq -r '[.status.nodes[] | select(.displayName=="publish")][0].phase // "missing"' <<<"$wf")"
[ "$pub" = "Succeeded" ] || fail "publish phase in release-1 is '$pub', expected Succeeded"
echo "PASS: integration retried once, package received 1.4.2 and publish ran"
