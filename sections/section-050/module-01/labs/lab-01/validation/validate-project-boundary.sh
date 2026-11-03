#!/usr/bin/env bash
# Grades the policy: one repository, exactly the staging and production destinations, no wildcards.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
p="$(kubectl -n argocd get appproject scout-team -o json 2>/dev/null)" || fail "AppProject scout-team is missing in the namespace argocd"
repos="$(jq -r '.spec.sourceRepos // [] | join(",")' <<<"$p")"
[ "$repos" = "$REPO" ] || fail "sourceRepos is '$repos', expected exactly $REPO"
dests="$(jq -r '[.spec.destinations // [] | .[] | "\(.server // .name // "")|\(.namespace // "")"] | sort | join(",")' <<<"$p")"
want="https://kubernetes.default.svc|starfleet-production,https://kubernetes.default.svc|starfleet-staging"
[ "$dests" = "$want" ] || fail "destinations are '$dests', expected $want"
wild="$(jq '[.spec.clusterResourceWhitelist // [] | .[] | select(.group=="*" or .kind=="*")] | length' <<<"$p")"
[ "$wild" = "0" ] || fail "clusterResourceWhitelist allows every kind; list only what the team needs, or nothing"
echo "PASS: scout-team allows the one repository and the staging and production namespaces only"
