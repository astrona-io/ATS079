#!/usr/bin/env bash
# Grades scout and bridge: healthy image, ready, updated in place, and for bridge a real readiness probe.
set -u
fail() { echo "FAIL: $*"; exit 1; }

for n in scout bridge; do
  d="$(kubectl -n starfleet get deploy "$n" -o json 2>/dev/null)" || fail "no Deployment $n"
  image="$(jq -r '.spec.template.spec.containers[0].image' <<<"$d")"
  [ "$image" = "ghcr.io/stefanprodan/podinfo:6.15.0" ] || fail "$n runs $image, expected ghcr.io/stefanprodan/podinfo:6.15.0"
  [ "$(jq -r '.spec.replicas' <<<"$d")" = "1" ] || fail "$n: spec.replicas is not 1"
  [ "$(jq -r '.status.readyReplicas // 0' <<<"$d")" = "1" ] || fail "$n has no ready replica"
  rev="$(jq -r '.metadata.annotations["deployment.kubernetes.io/revision"] // "0"' <<<"$d")"
  [ "$rev" -ge 2 ] || fail "$n is at revision $rev; it was recreated instead of updated"
  e="$(kubectl -n starfleet get endpointslices -l kubernetes.io/service-name="$n" -o json | jq '[.items[].endpoints[] | select(.conditions.ready==true)] | length')"
  [ "$e" -ge 1 ] || fail "the Service $n has no ready endpoint"
done
d="$(kubectl -n starfleet get deploy bridge -o json)"
path="$(jq -r '.spec.template.spec.containers[0].readinessProbe.httpGet.path // ""' <<<"$d")"
port="$(jq -r '.spec.template.spec.containers[0].readinessProbe.httpGet.port // ""' <<<"$d")"
[ "$path" = "/readyz" ] || fail "bridge readiness probe path is '$path', expected /readyz"
{ [ "$port" = "http" ] || [ "$port" = "9898" ]; } || fail "bridge readiness probe port is '$port', expected http or 9898"
echo "PASS: scout and bridge run 6.15.0, are ready and were updated in place; bridge probes /readyz on the application port"
