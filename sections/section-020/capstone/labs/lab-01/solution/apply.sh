#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/bridge-probe.yaml" <<'YAML'
spec:
  template:
    spec:
      containers:
        - name: bridge
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
YAML
cat > "$WORK/incident-record.yaml" <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: incident-record
  namespace: starfleet
data:
  severity: "2"
  status: resolved
  scout: "The release used an image tag that does not exist, so the pod could not pull its image."
  probe: "The ConfigMap probe-config had no key mode, so the container could not be created."
  bridge: "The readiness probe checked port 9899, so the pod never became ready and received no traffic."
  timeline: |
    three services down after the change window: image pull, config error, failing readiness
    set the scout image, added the key mode to probe-config, corrected the probe port of bridge
YAML

kubectl -n starfleet set image deploy/scout scout=ghcr.io/stefanprodan/podinfo:6.15.0
kubectl -n starfleet patch configmap probe-config --type merge -p '{"data":{"mode":"standard"}}'
kubectl -n starfleet patch deploy/bridge --patch-file "$WORK/bridge-probe.yaml"
kubectl apply -f "$WORK/incident-record.yaml"
for d in scout probe bridge; do kubectl -n starfleet rollout status deploy/$d --timeout=180s; done
