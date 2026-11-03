#!/usr/bin/env bash
# Grades the Git side: a PreSync hook Job with a delete policy, listed in the staging overlay.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
kust="$(git_file overlays/staging/kustomization.yaml)"
grep -q 'scout-presync-check.yaml' <<<"$kust" || fail "overlays/staging/kustomization.yaml does not list scout-presync-check.yaml under resources"
job="$(git_file overlays/staging/scout-presync-check.yaml)"
grep -q 'kind: Job' <<<"$job" || fail "overlays/staging/scout-presync-check.yaml is missing or is not a Job"
grep -q 'name: scout-presync-check' <<<"$job" || fail "the Job is not named scout-presync-check"
grep -Eq 'argocd.argoproj.io/hook: *"?PreSync"?' <<<"$job" || fail "the Job has no argocd.argoproj.io/hook: PreSync annotation"
grep -Eq 'argocd.argoproj.io/hook-delete-policy: *"?(BeforeHookCreation|HookSucceeded)"?' <<<"$job" || fail "the Job has no hook-delete-policy of BeforeHookCreation or HookSucceeded"
echo "PASS: Git holds the PreSync hook Job and the staging overlay lists it"
