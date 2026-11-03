#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
AUTH="platform:starfleet-gitops"
LOCAL_PORT=$(( 30000 + RANDOM % 20000 ))
kubectl -n gitea port-forward svc/gitea-http "$LOCAL_PORT:3000" >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true; rm -rf "$WORK"' EXIT
for i in $(seq 1 30); do curl -fs "http://127.0.0.1:$LOCAL_PORT/api/v1/version" >/dev/null 2>&1 && break; sleep 1; done

git clone -q "http://$AUTH@127.0.0.1:$LOCAL_PORT/starfleet/scout-deploy.git" "$WORK/scout-deploy"
cd "$WORK/scout-deploy"
cat > overlays/staging/scout-presync-check.yaml <<'YAML'
apiVersion: batch/v1
kind: Job
metadata:
  name: scout-presync-check
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: check
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "echo schema check passed"]
YAML
sed -i.bak 's#  - ../../base#  - ../../base\n  - scout-presync-check.yaml#' overlays/staging/kustomization.yaml
rm -f overlays/staging/kustomization.yaml.bak
git add -A
git -c user.name=ci -c user.email=ci@starfleet.local commit -q -m "add presync check to staging"
git push -q origin main

kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd wait --for=jsonpath='{.status.sync.revision}'="$(git rev-parse HEAD)" application/scout-staging --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.operationState.phase}'=Succeeded application/scout-staging --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout-staging --timeout=240s
