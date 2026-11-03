#!/usr/bin/env bash
# Grades the result: the generated Applications exist, are owned by the ApplicationSet and are delivered; the excluded one is absent.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
for app in scout-staging scout-production; do
  owner="$(kubectl -n argocd get application "$app" -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}' 2>/dev/null)"
  [ "$owner" = "ApplicationSet/scout-folders" ] || fail "$app is owned by '$owner', expected ApplicationSet/scout-folders"
done
app_ok scout-staging starfleet-staging 1
app_ok scout-production starfleet-production 2
kubectl -n argocd get application scout-preview >/dev/null 2>&1 && fail "Application scout-preview exists, but overlays/preview must be excluded"
n="$(kubectl -n starfleet-preview get deploy,svc -o name 2>/dev/null | wc -l | tr -d ' ')"
[ "$n" = "0" ] || fail "starfleet-preview holds $n objects, expected none"
echo "PASS: staging and production are generated and delivered, and preview is excluded"
