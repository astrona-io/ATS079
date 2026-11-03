#!/usr/bin/env bash
# Grades the delivery: Argo CD compared the head commit, the result is Healthy, and the change did not come from kubectl.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
check_app scout-staging starfleet-staging 1
echo "PASS: scout-staging is Synced and Healthy at the head commit and runs 6.15.0"
