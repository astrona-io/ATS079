#!/usr/bin/env bash
# Shared helpers for the graders. Sourced, not run on its own.
fail() { echo "FAIL: $*"; exit 1; }

# gitea <api path below the repository>: calls the Git server from the client pod.
gitea() {
  kubectl -n starfleet exec deploy/shuttle -- curl -s --max-time 10 -u platform:starfleet-gitops \
    "http://gitea-http.gitea.svc:3000/api/v1/repos/starfleet/scout-deploy/$1"
}
# git_file <path>: prints a file from the main branch.
git_file() { gitea "raw/$1?ref=main"; }
head_sha() { gitea "branches/main" | jq -r '.commit.id // empty'; }
# last_commit_for <path>: the newest commit that changed the path.
last_commit_for() { gitea "commits?path=$1&limit=1" | jq -r '.[0].sha // empty'; }

# check_app <application> <namespace> <replicas>: Synced, Healthy, at head, owned by Argo CD, running 6.15.0.
check_app() {
  local app="$1" ns="$2" want="$3" head
  kubectl -n argocd get application "$app" >/dev/null 2>&1 || fail "Application $app is missing"
  head="$(head_sha)"; [ -n "$head" ] || fail "could not read the head commit from Git"
  get() { kubectl -n argocd get application "$app" -o jsonpath="$1"; }
  [ "$(get '{.status.sync.status}')" = "Synced" ] || fail "$app sync status is '$(get '{.status.sync.status}')', expected Synced"
  [ "$(get '{.status.health.status}')" = "Healthy" ] || fail "$app health status is '$(get '{.status.health.status}')', expected Healthy"
  [ "$(get '{.status.sync.revision}')" = "$head" ] || fail "$app compared revision $(get '{.status.sync.revision}'), but Git is at $head; ask for a refresh"
  local image; image="$(kubectl -n "$ns" get deploy scout -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
  [ "$image" = "ghcr.io/stefanprodan/podinfo:6.15.0" ] || fail "$app: Deployment scout runs '$image', expected ghcr.io/stefanprodan/podinfo:6.15.0"
  local ready; ready="$(kubectl -n "$ns" get deploy scout -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  [ "${ready:-0}" = "$want" ] || fail "$app: $ready ready replicas, expected $want"
  local tracking; tracking="$(kubectl -n "$ns" get deploy scout -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null)"
  [[ "$tracking" == $app:* ]] || fail "$app: Deployment scout is not tracked by the Application"
  local managers; managers="$(kubectl -n "$ns" get deploy scout -o json | jq -r '[.metadata.managedFields[].manager] | join(",")')"
  [[ "$managers" != *kubectl* ]] || fail "$app: Deployment scout was changed with kubectl ($managers); change Git instead"
}
