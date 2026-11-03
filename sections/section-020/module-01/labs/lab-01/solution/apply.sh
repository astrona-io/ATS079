#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/incident-record.yaml" <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: incident-record
  namespace: starfleet
data:
  severity: "2"
  cause: "The release set the image tag 6.15.99, which does not exist, so the new pod could not pull its image."
  mitigation: rollback
  status: resolved
  timeline: |
    rollout of scout stalled with ImagePullBackOff, old pods kept serving
    rolled back with kubectl rollout undo, 2 of 2 replicas ready on 6.15.0
YAML

kubectl -n starfleet rollout undo deploy/scout
kubectl -n starfleet rollout status deploy/scout --timeout=180s
kubectl apply -f "$WORK/incident-record.yaml"
