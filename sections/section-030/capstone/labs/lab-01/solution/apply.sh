#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$(dirname "$WORK/overlays/staging/kustomization.yaml")"
cat > "$WORK/overlays/staging/kustomization.yaml" <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: starfleet-staging
resources:
  - ../../base
labels:
  - pairs:
      environment: staging
images:
  - name: ghcr.io/stefanprodan/podinfo
    newTag: 6.15.0
replicas:
  - name: scout
    count: 1
patches:
  - path: message.yaml
YAML
mkdir -p "$(dirname "$WORK/overlays/production/kustomization.yaml")"
cat > "$WORK/overlays/production/kustomization.yaml" <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: starfleet-production
resources:
  - ../../base
labels:
  - pairs:
      environment: production
images:
  - name: ghcr.io/stefanprodan/podinfo
    newTag: 6.15.0
replicas:
  - name: scout
    count: 2
patches:
  - path: message.yaml
YAML

AUTH="platform:starfleet-gitops"
LOCAL_PORT=$(( 30000 + RANDOM % 20000 ))
kubectl -n gitea port-forward svc/gitea-http "$LOCAL_PORT:3000" >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true; rm -rf "$WORK"' EXIT
for i in $(seq 1 30); do curl -fs "http://127.0.0.1:$LOCAL_PORT/api/v1/version" >/dev/null 2>&1 && break; sleep 1; done

git clone -q "http://$AUTH@127.0.0.1:$LOCAL_PORT/starfleet/scout-deploy.git" "$WORK/scout-deploy"
cd "$WORK/scout-deploy"
promote() {
  local env="$1" ns="$2"
  cp "$WORK/overlays/$env/kustomization.yaml" "overlays/$env/kustomization.yaml"
  git add "overlays/$env/kustomization.yaml"
  git -c user.name=ci -c user.email=ci@starfleet.local commit -q -m "promote scout to 6.15.0 in $env"
  git push -q origin main
  kubectl -n argocd annotate application "scout-$env" argocd.argoproj.io/refresh=hard --overwrite
  kubectl -n argocd wait --for=jsonpath='{.status.sync.revision}'="$(git rev-parse HEAD)" "application/scout-$env" --timeout=240s
  kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced "application/scout-$env" --timeout=240s
  kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy "application/scout-$env" --timeout=240s
  kubectl -n "$ns" rollout status deploy/scout --timeout=180s
}
promote staging starfleet-staging
promote production starfleet-production
# The staging Application compared the production commit as well, so wait for the head commit there too.
kubectl -n argocd annotate application scout-staging argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd wait --for=jsonpath='{.status.sync.revision}'="$(git rev-parse HEAD)" application/scout-staging --timeout=240s

kubectl -n starfleet create configmap delivery-record \
  --from-literal=staging-commit="$(git log -1 --format=%H -- overlays/staging/kustomization.yaml)" \
  --from-literal=production-commit="$(git log -1 --format=%H -- overlays/production/kustomization.yaml)" \
  --from-literal=version=6.15.0
