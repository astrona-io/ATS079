#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$(dirname "$WORK/scout-team.yaml")"
cat > "$WORK/scout-team.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: scout-team
  namespace: argocd
spec:
  description: The scout team may deliver to staging and production
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet-staging
    - server: https://kubernetes.default.svc
      namespace: starfleet-production
YAML
mkdir -p "$(dirname "$WORK/scout-staging.yaml")"
cat > "$WORK/scout-staging.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: scout-staging
  namespace: argocd
spec:
  project: scout-team
  source:
    repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
    targetRevision: main
    path: overlays/staging
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet-staging
  syncPolicy:
    automated: {}
YAML
mkdir -p "$(dirname "$WORK/scout-production.yaml")"
cat > "$WORK/scout-production.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: scout-production
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: scout-team
  source:
    repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
    targetRevision: main
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet-production
  syncPolicy:
    automated: {}
YAML

kubectl apply -f "$WORK/scout-team.yaml"
kubectl apply -f "$WORK/scout-staging.yaml"
kubectl apply -f "$WORK/scout-production.yaml"
for app in scout-staging scout-production; do
  kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced "application/$app" --timeout=240s
  kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy "application/$app" --timeout=240s
done
kubectl -n starfleet-staging rollout status deploy/scout --timeout=180s
kubectl -n starfleet-production rollout status deploy/scout --timeout=180s
