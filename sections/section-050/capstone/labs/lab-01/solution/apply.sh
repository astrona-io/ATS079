#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$(dirname "$WORK/scout-envs.yaml")"
cat > "$WORK/scout-envs.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: scout-envs
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - list:
        elements:
          - env: staging
          - env: production
          - env: preview
  template:
    metadata:
      name: 'scout-{{.env}}'
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: scout-team
      source:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        targetRevision: main
        path: 'overlays/{{.env}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'starfleet-{{.env}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
YAML
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
mkdir -p "$(dirname "$WORK/scout-envs-final.yaml")"
cat > "$WORK/scout-envs-final.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: scout-envs
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - list:
        elements:
          - env: staging
          - env: production
  template:
    metadata:
      name: 'scout-{{.env}}'
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: scout-team
      source:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        targetRevision: main
        path: 'overlays/{{.env}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'starfleet-{{.env}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
YAML

kubectl apply -f "$WORK/scout-envs.yaml"
for env in staging production preview; do
  for i in $(seq 1 60); do kubectl -n argocd get application "scout-$env" >/dev/null 2>&1 && break; sleep 2; done
  kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced "application/scout-$env" --timeout=240s
  kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy "application/scout-$env" --timeout=240s
done

AUTH="platform:starfleet-gitops"
LOCAL_PORT=$(( 30000 + RANDOM % 20000 ))
kubectl -n gitea port-forward svc/gitea-http "$LOCAL_PORT:3000" >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true; rm -rf "$WORK"' EXIT
for i in $(seq 1 30); do curl -fs "http://127.0.0.1:$LOCAL_PORT/api/v1/version" >/dev/null 2>&1 && break; sleep 1; done

git clone -q "http://$AUTH@127.0.0.1:$LOCAL_PORT/starfleet/scout-deploy.git" "$WORK/scout-deploy"
cd "$WORK/scout-deploy"
promote() {
  local env="$1"
  cp "$WORK/overlays/$env/kustomization.yaml" "overlays/$env/kustomization.yaml"
  git add "overlays/$env/kustomization.yaml"
  git -c user.name=ci -c user.email=ci@starfleet.local commit -q -m "promote scout to 6.15.0 in $env"
  git push -q origin main
}
promote staging
promote production
for env in staging production; do
  kubectl -n argocd annotate application "scout-$env" argocd.argoproj.io/refresh=hard --overwrite
  kubectl -n argocd wait --for=jsonpath='{.status.sync.revision}'="$(git rev-parse HEAD)" "application/scout-$env" --timeout=240s
  kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced "application/scout-$env" --timeout=240s
  kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy "application/scout-$env" --timeout=240s
  kubectl -n "starfleet-$env" rollout status deploy/scout --timeout=180s
done

kubectl apply -f "$WORK/scout-envs-final.yaml"
kubectl -n argocd wait --for=delete application/scout-preview --timeout=240s
