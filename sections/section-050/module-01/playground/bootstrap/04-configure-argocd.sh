#!/usr/bin/env bash
# Plumbing: repository credentials for Argo CD. No project and no Application exist.
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: repo-scout-deploy
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
  username: platform
  password: starfleet-gitops
YAML

