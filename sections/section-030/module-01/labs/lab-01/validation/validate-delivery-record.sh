#!/usr/bin/env bash
# Grades the record: environment, version, the full head commit and health.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
head="$(head_sha)"; [ -n "$head" ] || fail "could not read the head commit from Git"
kubectl -n starfleet get configmap delivery-record >/dev/null 2>&1 || fail "ConfigMap delivery-record is missing in the namespace starfleet"
val() { kubectl -n starfleet get configmap delivery-record -o jsonpath="{.data['$1']}"; }
[ "$(val environment)" = "staging" ] || fail "environment is '$(val environment)', expected staging"
[ "$(val version)" = "6.15.0" ] || fail "version is '$(val version)', expected 6.15.0"
[ "$(val commit)" = "$head" ] || fail "commit is '$(val commit)', expected the full head commit $head"
[ "$(val health)" = "Healthy" ] || fail "health is '$(val health)', expected Healthy"
echo "PASS: delivery-record names staging, 6.15.0, commit $head and Healthy"
