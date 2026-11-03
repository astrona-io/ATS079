#!/usr/bin/env bash
# Grades the record: the commit that changed each overlay, and the version.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
s="$(last_commit_for overlays/staging/kustomization.yaml)"; p="$(last_commit_for overlays/production/kustomization.yaml)"
[ -n "$s" ] && [ -n "$p" ] || fail "could not read the commits of the overlays from Git"
kubectl -n starfleet get configmap delivery-record >/dev/null 2>&1 || fail "ConfigMap delivery-record is missing in the namespace starfleet"
val() { kubectl -n starfleet get configmap delivery-record -o jsonpath="{.data['$1']}"; }
[ "$(val staging-commit)" = "$s" ] || fail "staging-commit is '$(val staging-commit)', expected $s"
[ "$(val production-commit)" = "$p" ] || fail "production-commit is '$(val production-commit)', expected $p"
[ "$(val version)" = "6.15.0" ] || fail "version is '$(val version)', expected 6.15.0"
echo "PASS: delivery-record names $s, $p and 6.15.0"
