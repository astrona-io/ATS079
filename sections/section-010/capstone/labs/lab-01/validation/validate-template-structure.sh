#!/usr/bin/env bash
# Grades the WorkflowTemplate: DAG shape, output reference, retry, parallelism and condition.
set -u
fail() { echo "FAIL: $*"; exit 1; }

tpl="$(kubectl -n starfleet get workflowtemplate release-pipeline -o json 2>/dev/null)" || fail "no WorkflowTemplate release-pipeline in starfleet"

[ "$(jq -r '.spec.entrypoint' <<<"$tpl")" = "pipeline" ] || fail "entrypoint is not pipeline"
[ "$(jq -r '.spec.serviceAccountName // ""' <<<"$tpl")" = "workflow-runner" ] || fail "serviceAccountName is not workflow-runner"
[ "$(jq -r '.spec.parallelism // 0' <<<"$tpl")" = "2" ] || fail "spec.parallelism is not 2"
[ "$(jq -r '.spec.arguments.parameters[]? | select(.name=="publish") | .value' <<<"$tpl")" = "false" ] || fail "parameter publish does not default to false"

dag='.spec.templates[] | select(.name=="pipeline") | .dag.tasks'
for t in checkout version lint test scan integration package publish notify; do
  jq -e "[$dag[] | select(.name==\"$t\")] | length == 1" <<<"$tpl" >/dev/null || fail "task $t is missing from the DAG template pipeline"
done
dep() { jq -r "$dag[] | select(.name==\"$1\") | (.depends // (.dependencies // [] | join(\" && \")))" <<<"$tpl"; }

[ -z "$(dep checkout)" ] || fail "checkout must have no dependency"
for t in version lint test scan; do
  [ "$(dep $t | tr -d ' ')" = "checkout" ] || fail "$t must depend on checkout only"
done
[[ "$(dep integration | tr -d ' ')" == "test" ]] || fail "integration must depend on test only"
pkg="$(dep package)"
for t in lint scan integration version; do
  [[ "$pkg" == *"$t"* ]] || fail "package does not depend on $t"
done
[[ "$pkg" != *Failed* && "$pkg" != *"||"* ]] || fail "package must need the success of all its dependencies"

ref="$(jq -r "$dag[] | select(.name==\"package\") | [.arguments.parameters[]? | .value] | join(\" \")" <<<"$tpl")"
[[ "$ref" == *"tasks.version.outputs.parameters.version"* ]] || fail "package does not receive tasks.version.outputs.parameters.version"

jq -r "$dag[] | select(.name==\"publish\") | .when // \"\"" <<<"$tpl" | grep -q "workflow.parameters.publish" || fail "publish has no when expression on the parameter publish"
nt="$(dep notify)"
[[ "$nt" == *package* && "$nt" == *Failed* ]] || fail "notify must run after package completed or after a failure"

# The retry: the template that integration uses has a retryStrategy with limit 2.
itpl="$(jq -r "$dag[] | select(.name==\"integration\") | .template" <<<"$tpl")"
[ "$(jq -r --arg n "$itpl" '.spec.templates[] | select(.name==$n) | .retryStrategy.limit // 0' <<<"$tpl")" = "2" ] || fail "the template of integration has no retryStrategy with limit 2"

# The output: some template declares an output parameter named version.
jq -e '[.spec.templates[] | .outputs.parameters[]? | select(.name=="version")] | length >= 1' <<<"$tpl" >/dev/null || fail "no template publishes an output parameter named version"
echo "PASS: release-pipeline has the required structure"
