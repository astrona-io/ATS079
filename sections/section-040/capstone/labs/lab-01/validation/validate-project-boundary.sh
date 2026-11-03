#!/usr/bin/env bash
# Grades the policy: the project lists exactly the one repository and the staging destination, with no wildcards.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
p="$(kubectl -n argocd get appproject scout-team -o json 2>/dev/null)" || fail "AppProject scout-team is missing in the namespace argocd"
repos="$(jq -r '.spec.sourceRepos // [] | join(",")' <<<"$p")"
[ "$repos" = "$REPO" ] || fail "sourceRepos is '$repos', expected exactly $REPO"
n="$(jq '.spec.destinations // [] | length' <<<"$p")"
[ "$n" = "1" ] || fail "the project has $n destinations, expected exactly one"
dest="$(jq -r '.spec.destinations[0] | "\(.server // .name // "")|\(.namespace // "")"' <<<"$p")"
[ "$dest" = "https://kubernetes.default.svc|starfleet-staging" ] || fail "the destination is '$dest', expected https://kubernetes.default.svc|starfleet-staging"
wild="$(jq '[.spec.clusterResourceWhitelist // [] | .[] | select(.group=="*" or .kind=="*")] | length' <<<"$p")"
[ "$wild" = "0" ] || fail "clusterResourceWhitelist allows every kind; list only what the team needs, or nothing"
echo "PASS: scout-team allows the one repository and the staging namespace only"
