#!/usr/bin/env bash
# Grades the habit of scoping before fixing: the failing Deployments were not changed or deleted.
set -u
fail() { echo "FAIL: $*"; exit 1; }

for d in probe beacon scout; do
  gen="$(kubectl -n starfleet get deploy "$d" -o jsonpath='{.metadata.generation}' 2>/dev/null)" || fail "Deployment $d is missing; do not delete workloads in this task"
  [ "$gen" = "1" ] || fail "Deployment $d was changed (generation $gen); this task only records the evidence"
done
echo "PASS: probe, beacon and scout are unchanged"
