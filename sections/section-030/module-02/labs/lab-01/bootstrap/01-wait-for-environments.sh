#!/usr/bin/env bash
# Plumbing: wait until both environments are rolled out before the learner starts.
set -euo pipefail
kubectl -n starfleet rollout status deploy/scout-blue --timeout=240s
kubectl -n starfleet rollout status deploy/scout-green --timeout=240s
echo "[lab] scout-blue (live) and scout-green are ready"
