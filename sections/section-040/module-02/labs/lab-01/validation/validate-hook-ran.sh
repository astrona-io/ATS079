#!/usr/bin/env bash
# Grades the cluster side: the last sync ran the hook in the PreSync phase and it succeeded.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
rows="$(kubectl -n argocd get application scout-staging -o jsonpath='{range .status.operationState.syncResult.resources[*]}{.kind}/{.name}/{.hookType}/{.hookPhase}{"\n"}{end}' 2>/dev/null)"
grep -q '^Job/scout-presync-check/PreSync/' <<<"$rows" || fail "the last sync did not run Job scout-presync-check as a PreSync hook; ask for a hard refresh and wait for the sync"
grep -q '^Job/scout-presync-check/PreSync/Succeeded$' <<<"$rows" || fail "the hook ran but its phase is not Succeeded: $(grep scout-presync-check <<<"$rows")"
echo "PASS: the PreSync hook Job ran and Succeeded"
