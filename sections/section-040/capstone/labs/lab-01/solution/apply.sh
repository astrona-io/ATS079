#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$(dirname "$WORK/scout-team-project.yaml")"
cat > "$WORK/scout-team-project.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: scout-team
  namespace: argocd
spec:
  description: The scout team may deliver to staging only
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet-staging
YAML
mkdir -p "$(dirname "$WORK/scout-production-attempt.yaml")"
cat > "$WORK/scout-production-attempt.yaml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: scout-production-attempt
  namespace: argocd
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

kubectl apply -f "$WORK/scout-team-project.yaml"
kubectl -n argocd patch application scout-staging --type merge -p '{"spec":{"project":"scout-team"}}'
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/scout-staging --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout-staging --timeout=240s
kubectl apply -f "$WORK/scout-production-attempt.yaml"
for i in $(seq 1 60); do
  if kubectl -n argocd get application scout-production-attempt -o jsonpath='{.status.conditions[*].type}' | grep -q InvalidSpecError; then exit 0; fi
  sleep 3
done
echo "scout-production-attempt did not get InvalidSpecError" >&2
exit 1
