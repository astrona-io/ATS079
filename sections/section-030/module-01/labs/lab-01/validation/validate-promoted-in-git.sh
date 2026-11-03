#!/usr/bin/env bash
# Grades the Git side: the staging overlay names 6.15.0 and the change is a new commit.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
file="$(git_file overlays/staging/kustomization.yaml)"
grep -q 'newTag: *"\?6\.15\.0"\?' <<<"$file" || fail "overlays/staging/kustomization.yaml in Git does not set newTag to 6.15.0"
count="$(gitea 'commits?limit=50' | jq 'length')"
[ "${count:-0}" -ge 2 ] || fail "Git has $count commit; the promotion must be a new commit"
echo "PASS: Git names 6.15.0 for staging and has $count commits"
