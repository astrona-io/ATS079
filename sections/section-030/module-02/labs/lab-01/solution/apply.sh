#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

kubectl -n starfleet patch deploy scout-blue --type merge -p '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
kubectl -n starfleet patch service scout -p '{"spec":{"selector":{"app":"scout","version":"green"}}}'

cat > "$WORK/configmap-release-record.yaml" <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-record
  namespace: starfleet
data:
  strategy: blue-green
  live: green
  previous: blue
  rollback: "kubectl -n starfleet patch service scout -p '{\"spec\":{\"selector\":{\"app\":\"scout\",\"version\":\"blue\"}}}'"
YAML
kubectl apply -f "$WORK/configmap-release-record.yaml"
