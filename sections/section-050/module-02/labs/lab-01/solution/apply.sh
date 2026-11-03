#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`. Keep in step with solution.md.
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: scout-folders
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - git:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        revision: main
        directories:
          - path: overlays/*
          - path: overlays/preview
            exclude: true
  template:
    metadata:
      name: 'scout-{{ .path.basename }}'
    spec:
      project: default
      source:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        targetRevision: main
        path: '{{ .path.path }}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'starfleet-{{ .path.basename }}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
YAML

for i in $(seq 1 60); do
  kubectl -n argocd get application scout-staging scout-production >/dev/null 2>&1 && break
  sleep 5
done
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout-staging --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout-production --timeout=300s
