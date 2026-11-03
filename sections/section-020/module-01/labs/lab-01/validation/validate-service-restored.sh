#!/usr/bin/env bash
# Grades the service: scout runs the good image with two ready replicas and the Service has two ready endpoints.
set -u
fail() { echo "FAIL: $*"; exit 1; }

d="$(kubectl -n starfleet get deploy scout -o json 2>/dev/null)" || fail "no Deployment scout in starfleet"
image="$(jq -r '.spec.template.spec.containers[0].image' <<<"$d")"
[ "$image" = "ghcr.io/stefanprodan/podinfo:6.15.0" ] || fail "scout runs $image, expected ghcr.io/stefanprodan/podinfo:6.15.0"
[ "$(jq -r '.spec.replicas' <<<"$d")" = "2" ] || fail "spec.replicas is not 2; keep the replica count"
ready="$(jq -r '.status.readyReplicas // 0' <<<"$d")"
updated="$(jq -r '.status.updatedReplicas // 0' <<<"$d")"
total="$(jq -r '.status.replicas // 0' <<<"$d")"
[ "$ready" = "2" ] || fail "readyReplicas is $ready, expected 2"
[ "$updated" = "2" ] && [ "$total" = "2" ] || fail "rollout is not complete (updatedReplicas=$updated, replicas=$total)"
reason="$(jq -r '.status.conditions[] | select(.type=="Progressing") | .reason' <<<"$d")"
[ "$reason" = "NewReplicaSetAvailable" ] || fail "Progressing reason is '$reason', expected NewReplicaSetAvailable"
n="$(kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=scout -o json | jq '[.items[].endpoints[] | select(.conditions.ready==true)] | length')"
[ "$n" -ge 2 ] || fail "the Service scout has $n ready endpoints, expected 2"
echo "PASS: scout runs 6.15.0 with 2 ready replicas and 2 ready endpoints"
