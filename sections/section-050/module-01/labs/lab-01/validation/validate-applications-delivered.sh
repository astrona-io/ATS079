#!/usr/bin/env bash
# Grades the two Applications: project, finalizer policy, delivery at the head commit, tracking.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fin="resources-finalizer.argocd.argoproj.io"
st="$(kubectl -n argocd get application scout-staging -o json 2>/dev/null)" || fail "Application scout-staging is missing in the namespace argocd"
pr="$(kubectl -n argocd get application scout-production -o json 2>/dev/null)" || fail "Application scout-production is missing in the namespace argocd"
[ "$(jq -r '.spec.source.path' <<<"$st")" = "overlays/staging" ] || fail "scout-staging must deliver the path overlays/staging"
[ "$(jq -r '.spec.source.path' <<<"$pr")" = "overlays/production" ] || fail "scout-production must deliver the path overlays/production"
[ "$(jq -r '.spec.destination.namespace' <<<"$st")" = "starfleet-staging" ] || fail "scout-staging must target the namespace starfleet-staging"
[ "$(jq -r '.spec.destination.namespace' <<<"$pr")" = "starfleet-production" ] || fail "scout-production must target the namespace starfleet-production"
[ "$(jq --arg f "$fin" '[.metadata.finalizers // [] | .[] | select(.==$f)] | length' <<<"$st")" = "0" ] || fail "scout-staging must not have the finalizer $fin"
[ "$(jq --arg f "$fin" '[.metadata.finalizers // [] | .[] | select(.==$f)] | length' <<<"$pr")" = "1" ] || fail "scout-production must have the finalizer $fin"
app_ok scout-staging starfleet-staging 1
app_ok scout-production starfleet-production 2
echo "PASS: both Applications are in scout-team, delivered at the head commit and tracked; only production has the finalizer"
