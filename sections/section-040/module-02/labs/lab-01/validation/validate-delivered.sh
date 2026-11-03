#!/usr/bin/env bash
# Grades the delivery: the hook did not change the application.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
app_ok scout-staging starfleet-staging 6.14.0
echo "PASS: scout-staging is Synced and Healthy at the head commit and runs 6.14.0"
