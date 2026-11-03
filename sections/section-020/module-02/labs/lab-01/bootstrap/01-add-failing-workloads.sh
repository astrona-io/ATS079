#!/usr/bin/env bash
# Plumbing: wait until the healthy scout is rolled out, then add two workloads that fail in different ways.
# probe exits with code 3 and goes into CrashLoopBackOff. beacon runs but its readiness probe checks a port that nothing listens on.
set -euo pipefail
kubectl -n starfleet rollout status deploy/scout --timeout=240s
kubectl apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe
  namespace: starfleet
  labels:
    app: probe
spec:
  replicas: 1
  selector:
    matchLabels:
      app: probe
  template:
    metadata:
      labels:
        app: probe
    spec:
      containers:
        - name: probe
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "echo probe failed to start; exit 3"]
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: beacon
  namespace: starfleet
  labels:
    app: beacon
spec:
  replicas: 1
  selector:
    matchLabels:
      app: beacon
  template:
    metadata:
      labels:
        app: beacon
    spec:
      containers:
        - name: beacon
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          ports:
            - name: http
              containerPort: 9898
          readinessProbe:
            httpGet:
              path: /readyz
              port: 9999
            periodSeconds: 5
          resources:
            requests:
              cpu: 10m
              memory: 32Mi
YAML
echo "[lab] Added the workloads probe and beacon to starfleet"
