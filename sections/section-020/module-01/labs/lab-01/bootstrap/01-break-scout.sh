#!/usr/bin/env bash
# Plumbing: wait until the healthy scout is rolled out, then release a bad image tag.
# This leaves a stalled rollout and a revision history that a rollback can use.
set -euo pipefail
kubectl -n starfleet rollout status deploy/scout --timeout=240s
kubectl -n starfleet set image deploy/scout scout=ghcr.io/stefanprodan/podinfo:6.15.99
kubectl -n starfleet annotate deploy/scout kubernetes.io/change-cause="release scout 6.15.99" --overwrite
echo "[lab] Released ghcr.io/stefanprodan/podinfo:6.15.99 to scout"
