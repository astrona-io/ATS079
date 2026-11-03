#!/usr/bin/env bash
# Grades the WorkflowTemplate structure: workspace claim, parameters, task order and the output parameter.
set -u
fail() { echo "FAIL: $*"; exit 1; }

tpl="$(kubectl -n starfleet get workflowtemplate build-pipeline -o json 2>/dev/null)" || fail "no WorkflowTemplate build-pipeline in starfleet"

[ "$(jq -r '.spec.entrypoint' <<<"$tpl")" = "pipeline" ] || fail "entrypoint is not pipeline"
[ "$(jq -r '.spec.serviceAccountName // ""' <<<"$tpl")" = "workflow-runner" ] || fail "serviceAccountName is not workflow-runner"
[ "$(jq -r '.spec.arguments.parameters[]? | select(.name=="version") | .value' <<<"$tpl")" = "1.4.0" ] || fail "parameter version does not default to 1.4.0"
[ "$(jq -r '.spec.arguments.parameters[]? | select(.name=="commit") | .value' <<<"$tpl")" = "3f9c2ab" ] || fail "parameter commit does not default to 3f9c2ab"
jq -e '[.spec.volumeClaimTemplates[]? | select(.metadata.name=="work")] | length == 1' <<<"$tpl" >/dev/null || fail "no volumeClaimTemplates entry named work"

dag='.spec.templates[] | select(.name=="pipeline") | .dag.tasks'
for t in build package deliver; do
  jq -e "[$dag[] | select(.name==\"$t\")] | length == 1" <<<"$tpl" >/dev/null || fail "task $t is missing from the DAG template pipeline"
done
dep() { jq -r "$dag[] | select(.name==\"$1\") | (.depends // (.dependencies // [] | join(\" && \")))" <<<"$tpl"; }
[[ "$(dep package)" == *build* ]] || fail "package does not depend on build"
[[ "$(dep deliver)" == *package* ]] || fail "deliver does not depend on package"

# The package template must publish an output parameter named image.
pkg_tpl="$(jq -r "$dag[] | select(.name==\"package\") | .template" <<<"$tpl")"
jq -e "[.spec.templates[] | select(.name==\"$pkg_tpl\") | .outputs.parameters[]? | select(.name==\"image\")] | length == 1" <<<"$tpl" >/dev/null || fail "the template of package has no output parameter named image"
echo "PASS: build-pipeline has the workspace, the parameters, the task order and the image output"
