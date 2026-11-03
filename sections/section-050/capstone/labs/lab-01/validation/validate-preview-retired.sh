#!/usr/bin/env bash
# Grades the retirement: the Application and its objects are gone, the namespace stays, and the element is gone from the list.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
s="$(kubectl -n argocd get applicationset scout-envs -o json 2>/dev/null)" || fail "ApplicationSet scout-envs is missing in the namespace argocd"
jq -e '[.spec.generators[0].list.elements // [] | .[] | select(.env=="preview")] | length == 0' <<<"$s" >/dev/null || fail "the list generator still has the element preview"
kubectl -n argocd get application scout-preview >/dev/null 2>&1 && fail "the Application scout-preview still exists; wait for the controller to delete it, and do not recreate it"
kubectl get namespace starfleet-preview >/dev/null 2>&1 || fail "the namespace starfleet-preview was deleted; only the delivered objects should be removed"
objs="$(kubectl -n starfleet-preview get deploy,svc -o name 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')"
[ "$objs" = "0" ] || fail "starfleet-preview still holds $objs delivered objects; the template must carry the finalizer so that the deletion removes them"
echo "PASS: preview is retired, its objects are gone and the namespace remains"
