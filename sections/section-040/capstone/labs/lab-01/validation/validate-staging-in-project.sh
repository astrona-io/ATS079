#!/usr/bin/env bash
# Grades the move: staging is in the project and still delivered by Argo CD.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
get() { kubectl -n argocd get application scout-staging -o jsonpath="$1" 2>/dev/null; }
[ -n "$(get '{.metadata.name}')" ] || fail "Application scout-staging is missing; move it, do not delete it"
[ "$(get '{.spec.project}')" = "scout-team" ] || fail "scout-staging is in the project '$(get '{.spec.project}')', expected scout-team"
[ "$(get '{.spec.destination.namespace}')" = "starfleet-staging" ] || fail "the destination namespace of scout-staging was changed"
[ "$(get '{.status.sync.status}')" = "Synced" ] || fail "sync status is '$(get '{.status.sync.status}')', expected Synced"
[ "$(get '{.status.health.status}')" = "Healthy" ] || fail "health status is '$(get '{.status.health.status}')', expected Healthy"
tracking="$(kubectl -n starfleet-staging get deploy scout -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null)"
[[ "$tracking" == scout-staging:* ]] || fail "Deployment scout is not tracked by scout-staging"
echo "PASS: scout-staging is in scout-team and is Synced and Healthy"
