#!/usr/bin/env bash
# Grades the Git side: a revert commit on top, the bad commit still in the history, staging back on 6.14.0.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
commits="$(gitea 'commits?limit=50')"
head_msg="$(jq -r '.[0].commit.message // empty' <<<"$commits")"
[[ "$head_msg" == Revert* ]] || fail "the head commit message is '${head_msg%%$'\n'*}', expected a revert commit"
jq -e '[.[].commit.message] | any(startswith("bump scout staging to 6.15.99"))' <<<"$commits" >/dev/null || fail "the bad commit is not in the history any more; revert it, do not remove it"
file="$(git_file overlays/staging/kustomization.yaml)"
grep -q 'newTag: *"\?6\.14\.0"\?' <<<"$file" || fail "overlays/staging/kustomization.yaml does not set newTag to 6.14.0"
echo "PASS: the head commit reverts the bad release, the history keeps it and staging names 6.14.0"
