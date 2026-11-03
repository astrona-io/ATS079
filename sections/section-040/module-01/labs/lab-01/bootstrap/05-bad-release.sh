#!/usr/bin/env bash
# Plumbing: push one more commit to main that bumps staging to a tag that does not exist,
# then ask Argo CD to refresh, so the lab starts with a failed delivery.
set -euo pipefail
AUTH="platform:starfleet-gitops"
LOCAL_PORT=$(( 30000 + RANDOM % 20000 ))
kubectl -n gitea port-forward svc/gitea-http "$LOCAL_PORT:3000" >/dev/null 2>&1 &
PF=$!
WORK="$(mktemp -d)"
trap 'kill $PF 2>/dev/null || true; rm -rf "$WORK"' EXIT
for i in $(seq 1 30); do curl -fs "http://127.0.0.1:$LOCAL_PORT/api/v1/version" >/dev/null 2>&1 && break; sleep 1; done
git clone -q "http://$AUTH@127.0.0.1:$LOCAL_PORT/starfleet/scout-deploy.git" "$WORK/repo"
cd "$WORK/repo"
sed -i.bak 's/newTag: 6.14.0/newTag: 6.15.99/' overlays/staging/kustomization.yaml
rm -f overlays/staging/kustomization.yaml.bak
git -c user.name=platform -c user.email=platform@starfleet.local commit -q -am "bump scout staging to 6.15.99"
git push -q origin main
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite >/dev/null
echo "[lab] Pushed the commit 'bump scout staging to 6.15.99'"
