#!/usr/bin/env bash
# Grades the ApplicationSet: one template with placeholders, a list of two environments, safe defaults, owned Applications.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fin="resources-finalizer.argocd.argoproj.io"
s="$(kubectl -n argocd get applicationset scout-envs -o json 2>/dev/null)" || fail "ApplicationSet scout-envs is missing in the namespace argocd"
[ "$(jq -r '.spec.goTemplate // false' <<<"$s")" = "true" ] || fail "spec.goTemplate must be true"
[ "$(jq '.spec.generators | length' <<<"$s")" = "1" ] || fail "the ApplicationSet must have exactly one generator"
envs="$(jq -r '[.spec.generators[0].list.elements // [] | .[].env] | sort | join(",")' <<<"$s")"
[ "$envs" = "production,staging" ] || fail "the list generator has the environments '$envs', expected production,staging"
for f in '.spec.template.metadata.name' '.spec.template.spec.source.path' '.spec.template.spec.destination.namespace'; do
  jq -e "$f | test(\"[{][{]\")" <<<"$s" >/dev/null || fail "$f must use a placeholder and not a fixed value"
done
[ "$(jq -r '.spec.template.spec.project' <<<"$s")" = "scout-team" ] || fail "the template must use the project scout-team"
[ "$(jq -r '.spec.template.spec.source.targetRevision' <<<"$s")" = "main" ] || fail "the template must follow the branch main"
[ "$(jq --arg f "$fin" '[.spec.template.metadata.finalizers // [] | .[] | select(.==$f)] | length' <<<"$s")" = "1" ] || fail "the template must carry the finalizer $fin"
[ "$(jq -r '.spec.template.spec.syncPolicy.automated.prune // false' <<<"$s")" = "true" ] || fail "the template must set automated prune to true"
[ "$(jq -r '.spec.template.spec.syncPolicy.automated.selfHeal // false' <<<"$s")" = "true" ] || fail "the template must set automated selfHeal to true"
for app in scout-staging scout-production; do
  a="$(kubectl -n argocd get application "$app" -o json 2>/dev/null)" || fail "Application $app is missing"
  [ "$(jq -r '[.metadata.ownerReferences // [] | .[] | select(.kind=="ApplicationSet" and .name=="scout-envs")] | length' <<<"$a")" = "1" ] || fail "$app is not owned by the ApplicationSet scout-envs; create it from the template and not by hand"
done
echo "PASS: scout-envs is a templated list of two environments and owns both Applications"
