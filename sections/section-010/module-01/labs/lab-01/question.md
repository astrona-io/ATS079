# Question

Solve this question on: `terminal`

The platform team runs its CI pipeline for the `scout` service with Argo Workflows in the namespace `starfleet`. Argo Workflows is installed and the service account `workflow-runner` exists. There is no pipeline yet. Write it as a `WorkflowTemplate`, run it once and keep the result.

Create the `WorkflowTemplate` `ci-pipeline` in `starfleet` with these properties:

1. The entrypoint is a DAG template named `pipeline`, and the pods run as the service account `workflow-runner`.
2. The tasks are `checkout`, `lint`, `test`, `package`, `publish` and `report`, each using a container template that runs `alpine:3.23`.
3. `lint` and `test` both depend on `checkout`. `lint` and `test` must not depend on each other, so they run in parallel. Each of them runs `sleep 10` so that the overlap is visible.
4. `package` depends on the success of both `lint` and `test`.
5. `publish` depends on `package` and runs only when the workflow parameter `publish` equals `true`. The default value of `publish` is `false`.
6. `report` runs after `package` completed, or after `lint` or `test` failed.

Then create a `Workflow` named `ci-run-1` in `starfleet` that uses the template `ci-pipeline` with the default parameter value. Wait until it finishes.

When you finish, these must be true:

- The template has the structure above.
- `ci-run-1` finished with the phase `Succeeded`.
- `lint` and `test` ran at the same time: each started before the other finished.
- `package` started after both `lint` and `test` finished.
- `publish` has the phase `Skipped`, and `report` ran.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
