#!/usr/bin/env bash
# Grades the policy by its behavior: a hand edit of production must be undone.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
get() { kubectl -n argocd get application scout-production -o jsonpath="$1" 2>/dev/null; }
[ "$(get '{.spec.syncPolicy.automated.prune}')" = "true" ] || fail "automated prune is not turned on in the generated Application"
[ "$(get '{.spec.syncPolicy.automated.selfHeal}')" = "true" ] || fail "automated selfHeal is not turned on in the generated Application"
kubectl -n starfleet-production scale deploy/scout --replicas=5 >/dev/null 2>&1 || fail "could not scale Deployment scout for the drift test"
for i in $(seq 1 40); do
  replicas="$(kubectl -n starfleet-production get deploy scout -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  [ "$replicas" = "2" ] && { echo "PASS: selfHeal is on and the hand edit of production was undone"; exit 0; }
  sleep 3
done
fail "the replicas stayed at $replicas two minutes after a hand edit; selfHeal does not undo it"
