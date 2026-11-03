#!/usr/bin/env bash
# Grades the shape of the ApplicationSet: a Git directory generator with an include and an exclude, Go templates, placeholders.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
as="$(kubectl -n argocd get applicationset scout-folders -o json 2>/dev/null)" || fail "ApplicationSet scout-folders is missing in the namespace argocd"
[ "$(jq -r '.spec.generators | length' <<<"$as")" = "1" ] || fail "expected exactly one generator"
[ "$(jq -r '.spec.generators[0].git.repoURL // empty' <<<"$as")" = "$REPO" ] || fail "the Git generator does not use the repository $REPO"
[ "$(jq -r '.spec.generators[0].git.revision // empty' <<<"$as")" = "main" ] || fail "the Git generator must read the revision main"
jq -e '[.spec.generators[0].git.directories // [] | .[] | select(.path=="overlays/*" and (.exclude // false) == false)] | length == 1' <<<"$as" >/dev/null || fail "directories must include the path overlays/*"
jq -e '[.spec.generators[0].git.directories // [] | .[] | select(.path=="overlays/preview" and .exclude == true)] | length == 1' <<<"$as" >/dev/null || fail "directories must exclude overlays/preview with exclude: true"
[ "$(jq -r '.spec.goTemplate // false' <<<"$as")" = "true" ] || fail "goTemplate must be true"
name="$(jq -r '.spec.template.metadata.name // empty' <<<"$as")"
path="$(jq -r '.spec.template.spec.source.path // empty' <<<"$as")"
ns="$(jq -r '.spec.template.spec.destination.namespace // empty' <<<"$as")"
[[ "$name" == *"{{"* ]] || fail "the template name '$name' has no placeholder"
[[ "$path" == *"{{"* ]] || fail "the template path '$path' has no placeholder"
[[ "$ns" == *"{{"* ]] || fail "the template namespace '$ns' has no placeholder"
echo "PASS: scout-folders reads overlays/* without overlays/preview and fills name, path and namespace from placeholders"
