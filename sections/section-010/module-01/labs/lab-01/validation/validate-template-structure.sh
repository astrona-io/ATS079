#!/usr/bin/env bash
# Grades the WorkflowTemplate structure: entrypoint, service account, task names and dependencies.
set -u
fail() { echo "FAIL: $*"; exit 1; }

tpl="$(kubectl -n starfleet get workflowtemplate ci-pipeline -o json 2>/dev/null)" || fail "no WorkflowTemplate ci-pipeline in starfleet"

[ "$(jq -r '.spec.entrypoint' <<<"$tpl")" = "pipeline" ] || fail "entrypoint is not pipeline"
[ "$(jq -r '.spec.serviceAccountName // ""' <<<"$tpl")" = "workflow-runner" ] || fail "serviceAccountName is not workflow-runner"
[ "$(jq -r '.spec.arguments.parameters[]? | select(.name=="publish") | .value' <<<"$tpl")" = "false" ] || fail "parameter publish does not default to false"

dag='.spec.templates[] | select(.name=="pipeline") | .dag.tasks'
for t in checkout lint test package publish report; do
  jq -e "[$dag[] | select(.name==\"$t\")] | length == 1" <<<"$tpl" >/dev/null || fail "task $t is missing from the DAG template pipeline"
done

dep() { jq -r "$dag[] | select(.name==\"$1\") | (.depends // (.dependencies // [] | join(\" && \")))" <<<"$tpl"; }

[[ "$(dep lint)" == *checkout* ]] || fail "lint does not depend on checkout"
[[ "$(dep test)" == *checkout* ]] || fail "test does not depend on checkout"
[[ "$(dep lint)" != *test* ]] || fail "lint depends on test, so the branches cannot run in parallel"
[[ "$(dep test)" != *lint* ]] || fail "test depends on lint, so the branches cannot run in parallel"
pkg="$(dep package)"
[[ "$pkg" == *lint* && "$pkg" == *test* ]] || fail "package does not depend on both lint and test"
[[ "$pkg" != *Failed* && "$pkg" != *Completed* && "$pkg" != *"||"* ]] || fail "package must need the success of lint and test, not a failure or an either condition"
[[ "$(dep publish)" == *package* ]] || fail "publish does not depend on package"
[ -n "$(jq -r "$dag[] | select(.name==\"publish\") | .when // \"\"" <<<"$tpl")" ] || fail "publish has no when expression"
jq -r "$dag[] | select(.name==\"publish\") | .when // \"\"" <<<"$tpl" | grep -q "workflow.parameters.publish" || fail "the when expression of publish does not use the parameter publish"
rep="$(dep report)"
[[ "$rep" == *package* && ( "$rep" == *Completed* || "$rep" == *Failed* ) ]] || fail "report must run after package completed or after a failure"

echo "PASS: ci-pipeline has the required DAG structure"
