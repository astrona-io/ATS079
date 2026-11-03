#!/usr/bin/env bash
# Grades the promotion: two commits in order, both environments delivered at the head commit, preview untouched in Git.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
for env in staging production; do
  grep -q 'newTag: *"\?6\.15\.0"\?' <<<"$(git_file overlays/$env/kustomization.yaml)" || fail "overlays/$env/kustomization.yaml in Git does not set newTag to 6.15.0"
done
grep -q 'newTag: *"\?6\.14\.0"\?' <<<"$(git_file overlays/preview/kustomization.yaml)" || fail "overlays/preview/kustomization.yaml must stay on 6.14.0"
s="$(last_commit_for overlays/staging/kustomization.yaml)"; p="$(last_commit_for overlays/production/kustomization.yaml)"
[ -n "$s" ] && [ -n "$p" ] || fail "could not read the commits of the overlays from Git"
[ "$s" != "$p" ] || fail "staging and production changed in the same commit; promote them in two commits"
order="$(gitea 'commits?limit=50' | jq -r --arg s "$s" --arg p "$p" '[.[].sha] | (index($p) < index($s))')"
[ "$order" = "true" ] || fail "the production commit is not newer than the staging commit; promote staging first"
check_app scout-staging starfleet-staging 1
check_app scout-production starfleet-production 2
echo "PASS: staging at ${s:0:8}, then production at ${p:0:8}, both delivered at the head commit"
