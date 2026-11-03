#!/usr/bin/env bash
# Grades the timing in the status of ci-run-1: lint and test overlap, package starts after both.
set -u
fail() { echo "FAIL: $*"; exit 1; }

wf="$(kubectl -n starfleet get workflow ci-run-1 -o json 2>/dev/null)" || fail "no Workflow ci-run-1 in starfleet"
node() { jq -r --arg n "$1" --arg f "$2" '[.status.nodes[] | select(.displayName==$n and .type=="Pod")][0][$f] // ""' <<<"$wf"; }
epoch() { date -u -d "$1" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" +%s 2>/dev/null; }

for t in lint test package; do
  [ -n "$(node $t startedAt)" ] || fail "task $t has no start time in the status"
  [ -n "$(node $t finishedAt)" ] || fail "task $t has no finish time in the status"
done

lint_start=$(epoch "$(node lint startedAt)"); lint_end=$(epoch "$(node lint finishedAt)")
test_start=$(epoch "$(node test startedAt)"); test_end=$(epoch "$(node test finishedAt)")
pkg_start=$(epoch "$(node package startedAt)")

[ "$lint_start" -lt "$test_end" ] && [ "$test_start" -lt "$lint_end" ] || fail "lint and test did not overlap in time, so they did not run in parallel"
[ "$pkg_start" -ge "$lint_end" ] && [ "$pkg_start" -ge "$test_end" ] || fail "package started before lint and test both finished"
echo "PASS: lint and test ran in parallel and package started after both"
