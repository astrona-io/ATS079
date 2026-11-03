#!/usr/bin/env bash
# Grades the boundary by trying to cross it: a temporary Application for the preview namespace must be refused.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
kubectl -n argocd get appproject scout-team >/dev/null 2>&1 || fail "AppProject scout-team is missing in the namespace argocd"
trap 'kubectl -n argocd delete application probe-preview --ignore-not-found --wait=false >/dev/null 2>&1' EXIT
kubectl apply -f - >/dev/null <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: probe-preview
  namespace: argocd
spec:
  project: scout-team
  source:
    repoURL: $REPO
    targetRevision: main
    path: overlays/preview
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet-preview
  syncPolicy:
    automated: {}
YAML
ok=0
for i in $(seq 1 40); do
  if kubectl -n argocd get application probe-preview -o jsonpath='{.status.conditions[*].type}' 2>/dev/null | grep -q InvalidSpecError; then ok=1; break; fi
  sleep 3
done
[ "$ok" = "1" ] || fail "the temporary Application for starfleet-preview did not get InvalidSpecError; the project must not allow the preview namespace"
objs="$(kubectl -n starfleet-preview get deploy,svc -o name 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')"
[ "$objs" = "0" ] || fail "starfleet-preview contains $objs delivered objects; the project must keep preview out"
echo "PASS: an Application for starfleet-preview is refused with InvalidSpecError and creates nothing"
