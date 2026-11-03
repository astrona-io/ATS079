#!/usr/bin/env bash
# Shared helpers for the graders. Sourced, not run on its own.
fail() { echo "FAIL: $*"; exit 1; }
REPO="http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git"
