# Question

Solve this question on: `terminal`

The release pipeline for the `scout` service must be a single Argo Workflows `WorkflowTemplate` in the namespace `starfleet`. Argo Workflows is installed and the service account `workflow-runner` exists. Write the pipeline, run it twice with different parameters and keep both runs.

Create the `WorkflowTemplate` `release-pipeline` with these properties:

1. The entrypoint is a DAG template named `pipeline`, the pods run as `workflow-runner`, and every container uses `alpine:3.23`. The workflow runs at most two pods at the same time (`spec.parallelism: 2`).
2. The tasks are `checkout`, `version`, `lint`, `test`, `scan`, `integration`, `package`, `publish` and `notify`.
3. `checkout` has no dependency. `version`, `lint`, `test` and `scan` depend on `checkout` only. `lint`, `test` and `scan` each run `sleep 10`.
4. `version` publishes an output parameter named `version` with the value `1.4.2`.
5. `integration` depends on `test`. Its first attempt must fail and a retry must succeed: give its template a `retryStrategy` with `limit: 2` and make the command exit with an error while `{{retries}}` is `0`, for example `test {{retries}} -ge 1`.
6. `package` depends on `lint`, `scan`, `integration` and `version`, all with success, and receives the value of the output `version` as an input parameter named `version`.
7. `publish` depends on `package` and runs only when the workflow parameter `publish` equals `true`. The default value of `publish` is `false`.
8. `notify` runs after `package` completed, or after `lint`, `test`, `scan` or `integration` failed.

Create two `Workflow` objects in `starfleet` that use the template:

- `release-1` with the parameter `publish` set to `true`.
- `release-2` with the parameter `publish` set to `false`.

Wait until both finish.

When you finish, these must be true:

- The template has the structure above.
- `release-1` and `release-2` finished with the phase `Succeeded`.
- In `release-1`, `integration` was attempted at least twice: the first attempt failed and the last one succeeded.
- In `release-1`, `package` received the version `1.4.2`, and `publish` ran.
- In `release-2`, `publish` was skipped.
- At no moment did `release-1` run more than two pods at the same time.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
