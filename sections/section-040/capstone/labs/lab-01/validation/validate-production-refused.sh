#!/usr/bin/env bash
# Grades the refusal: the Application exists in the project, carries InvalidSpecError and creates nothing in production.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
a="$(kubectl -n argocd get application scout-production-attempt -o json 2>/dev/null)" || fail "Application scout-production-attempt is missing in the namespace argocd"
[ "$(jq -r '.spec.project' <<<"$a")" = "scout-team" ] || fail "scout-production-attempt must belong to the project scout-team"
[ "$(jq -r '.spec.source.path' <<<"$a")" = "overlays/production" ] || fail "scout-production-attempt must deliver the path overlays/production"
[ "$(jq -r '.spec.destination.namespace' <<<"$a")" = "starfleet-production" ] || fail "scout-production-attempt must target the namespace starfleet-production"
jq -e '[.status.conditions // [] | .[] | select(.type=="InvalidSpecError")] | length > 0' <<<"$a" >/dev/null || fail "no InvalidSpecError condition yet; wait a short time, or check that the project does not allow the production namespace"
objs="$(kubectl -n starfleet-production get deploy,svc -o name 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')"
[ "$objs" = "0" ] || fail "starfleet-production contains $objs delivered objects; the project must keep production out"
echo "PASS: production is refused with InvalidSpecError and nothing was created there"
