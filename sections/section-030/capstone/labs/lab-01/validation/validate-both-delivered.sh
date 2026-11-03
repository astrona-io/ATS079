#!/usr/bin/env bash
# Grades the delivery of both environments at the head commit.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
check_app scout-staging starfleet-staging 1
check_app scout-production starfleet-production 2
echo "PASS: both Applications are Synced and Healthy at the head commit and run 6.15.0"
