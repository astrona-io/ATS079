#!/usr/bin/env bash
# Grades the method: the Deployment was not recreated, so the bad ReplicaSet still exists with zero replicas.
set -u
fail() { echo "FAIL: $*"; exit 1; }

uid="$(kubectl -n starfleet get deploy scout -o jsonpath='{.metadata.uid}' 2>/dev/null)" || fail "no Deployment scout"
rs="$(kubectl -n starfleet get rs -o json | jq --arg uid "$uid" '[.items[] | select(.metadata.ownerReferences[]?.uid==$uid)]')"
count="$(jq 'length' <<<"$rs")"
[ "$count" -ge 2 ] || fail "scout owns $count ReplicaSets; the history was removed or the Deployment was recreated"
bad="$(jq '[.[] | select(.spec.template.spec.containers[0].image=="ghcr.io/stefanprodan/podinfo:6.15.99")] | length' <<<"$rs")"
[ "$bad" -ge 1 ] || fail "the ReplicaSet of the bad release (6.15.99) is gone; roll back, do not recreate the Deployment"
bad_active="$(jq '[.[] | select(.spec.template.spec.containers[0].image=="ghcr.io/stefanprodan/podinfo:6.15.99") | .spec.replicas] | add' <<<"$rs")"
[ "$bad_active" = "0" ] || fail "the bad ReplicaSet still has $bad_active desired replicas"
echo "PASS: the Deployment kept its history and the bad ReplicaSet is scaled to 0"
