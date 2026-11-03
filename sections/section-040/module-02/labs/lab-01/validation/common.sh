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

# app_ok <application> <namespace> <image tag>: Synced, Healthy, at the head commit, running the tag.
app_ok() {
  local app="$1" ns="$2" tag="$3" head
  kubectl -n argocd get application "$app" >/dev/null 2>&1 || fail "Application $app is missing"
  head="$(head_sha)"; [ -n "$head" ] || fail "could not read the head commit from Git"
  get() { kubectl -n argocd get application "$app" -o jsonpath="$1"; }
  [ "$(get '{.status.sync.status}')" = "Synced" ] || fail "$app sync status is '$(get '{.status.sync.status}')', expected Synced"
  [ "$(get '{.status.health.status}')" = "Healthy" ] || fail "$app health status is '$(get '{.status.health.status}')', expected Healthy"
  [ "$(get '{.status.sync.revision}')" = "$head" ] || fail "$app compared revision $(get '{.status.sync.revision}'), but Git is at $head; ask for a refresh"
  local image; image="$(kubectl -n "$ns" get deploy scout -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
  [ "$image" = "ghcr.io/stefanprodan/podinfo:$tag" ] || fail "Deployment scout runs '$image', expected ghcr.io/stefanprodan/podinfo:$tag"
  local ready; ready="$(kubectl -n "$ns" get deploy scout -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  [ "${ready:-0}" = "1" ] || fail "${ready:-0} ready replicas, expected 1"
}
