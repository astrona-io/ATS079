#!/usr/bin/env bash
# Grades the rollback path and the rolling update settings: blue still runs with two ready replicas and has the strategy.
set -u
fail() { echo "FAIL: $*"; exit 1; }

get() { kubectl -n starfleet get deploy scout-blue -o jsonpath="$1" 2>/dev/null; }
[ -n "$(get '{.metadata.name}')" ] || fail "Deployment scout-blue is missing; keep it for the rollback"
[ "$(get '{.status.readyReplicas}')" = "2" ] || fail "scout-blue has '$(get '{.status.readyReplicas}')' ready replicas, expected 2"
[ "$(get '{.spec.strategy.type}')" = "RollingUpdate" ] || fail "scout-blue strategy type is '$(get '{.spec.strategy.type}')', expected RollingUpdate"
[ "$(get '{.spec.strategy.rollingUpdate.maxSurge}')" = "1" ] || fail "maxSurge of scout-blue is '$(get '{.spec.strategy.rollingUpdate.maxSurge}')', expected 1"
[ "$(get '{.spec.strategy.rollingUpdate.maxUnavailable}')" = "0" ] || fail "maxUnavailable of scout-blue is '$(get '{.spec.strategy.rollingUpdate.maxUnavailable}')', expected 0"
echo "PASS: scout-blue still has two ready replicas and maxSurge 1 with maxUnavailable 0"
