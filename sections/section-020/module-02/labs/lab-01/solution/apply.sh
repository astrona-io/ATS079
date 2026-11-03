#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Wait until the crash loop has produced a terminated state.
for i in $(seq 1 60); do
  code="$(kubectl -n starfleet get pods -l app=probe -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}' 2>/dev/null || true)"
  [ -n "$code" ] && break
  sleep 3
done

cat > "$WORK/configmap-detection-record.yaml" <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: detection-record
  namespace: starfleet
data:
  crashing: probe
  exit-code: "${code}"
  not-ready: beacon
  healthy: scout
  error-budget-minutes: "43.2"
  severity: "3"
  signal: "The container status of probe shows exit code ${code} and the event BackOff."
YAML
kubectl apply -f "$WORK/configmap-detection-record.yaml"
