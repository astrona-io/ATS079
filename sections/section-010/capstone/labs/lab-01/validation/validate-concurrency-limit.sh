#!/usr/bin/env bash
# Grades the timing of release-1: never more than two task pods at the same moment.
set -u
fail() { echo "FAIL: $*"; exit 1; }

wf="$(kubectl -n starfleet get workflow release-1 -o json 2>/dev/null)" || fail "no Workflow release-1 in starfleet"
max="$(jq '
  [.status.nodes[] | select(.type=="Pod" and .startedAt != null and .finishedAt != null)
    | {s: (.startedAt | fromdateiso8601), e: (.finishedAt | fromdateiso8601)}] as $pods
  | if ($pods | length) == 0 then -1
    else [ $pods[] | .s as $t | [$pods[] | select(.s <= $t and .e > $t)] | length ] | max end' <<<"$wf")"
[ "$max" -ge 1 ] || fail "release-1 has no finished task pods in its status"
[ "$max" -le 2 ] || fail "$max task pods ran at the same moment, expected at most 2"
echo "PASS: at most $max task pods ran at the same moment in release-1"
