#!/usr/bin/env bash
# Grades probe: the configuration was completed, the reference to it is intact and the pod is ready.
set -u
fail() { echo "FAIL: $*"; exit 1; }

d="$(kubectl -n starfleet get deploy probe -o json 2>/dev/null)" || fail "no Deployment probe"
ref="$(jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="MODE") | .valueFrom.configMapKeyRef | "\(.name)/\(.key)"' <<<"$d")"
[ "$ref" = "probe-config/mode" ] || fail "probe must still read MODE from probe-config key mode (found '${ref:-nothing}')"
v="$(kubectl -n starfleet get configmap probe-config -o jsonpath='{.data.mode}' 2>/dev/null)"
[ -n "$v" ] || fail "the ConfigMap probe-config has no non-empty key mode"
[ "$(jq -r '.spec.replicas' <<<"$d")" = "1" ] || fail "probe: spec.replicas is not 1"
[ "$(jq -r '.status.readyReplicas // 0' <<<"$d")" = "1" ] || fail "probe has no ready replica"
e="$(kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=probe -o json | jq '[.items[].endpoints[] | select(.conditions.ready==true)] | length')"
[ "$e" -ge 1 ] || fail "the Service probe has no ready endpoint"
echo "PASS: probe reads MODE from probe-config/mode, the key exists and the pod is ready"
