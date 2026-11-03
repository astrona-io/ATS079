#!/usr/bin/env bash
# Grades the switch: the Service selects green, every endpoint is a green pod and a request returns 6.15.0.
set -u
fail() { echo "FAIL: $*"; exit 1; }

sel="$(kubectl -n starfleet get service scout -o jsonpath='{.spec.selector.version}' 2>/dev/null)" || fail "Service scout is missing"
[ "$sel" = "green" ] || fail "the Service selector version is '$sel', expected green"

green_ips="$(kubectl -n starfleet get pods -l app=scout,version=green -o jsonpath='{.items[*].status.podIP}')"
end_ips="$(kubectl -n starfleet get endpoints scout -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)"
[ -n "$end_ips" ] || fail "the Service scout has no ready endpoints"
for ip in $end_ips; do
  [[ " $green_ips " == *" $ip "* ]] || fail "endpoint $ip is not a green pod"
done
count="$(wc -w <<<"$end_ips" | tr -d ' ')"
[ "$count" = "2" ] || fail "$count endpoints, expected 2 green pods"

body="$(kubectl -n starfleet exec deploy/shuttle -- curl -s --max-time 5 http://scout/ 2>/dev/null)"
grep -q '"version".*6\.15\.0' <<<"$body" || fail "a request through the Service did not return version 6.15.0"
echo "PASS: the Service sends traffic to the two green pods and returns 6.15.0"
