# Overview: DAG Dependencies, Conditional Tasks And Parallel Work (Playground)

This is a **playground**, not a lab. It starts a cluster with Argo Workflows and waits. There is no task, no `astrona submit` and no pass or fail. Write workflows, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it. You need `jq` on your machine to read workflow status.
- **Argo Workflows v4.1.6**, installed into the namespace `starfleet`. The workflow controller watches only that namespace. The Argo server (web page and API) is not installed, so you work with `kubectl`.
- The service account `workflow-runner` in `starfleet`. It has one Role that lets the executor write task results. Set `serviceAccountName: workflow-runner` in every workflow you write.
- `shuttle`, a client pod with `curl`, in `starfleet`.
- No `WorkflowTemplate` and no `Workflow` exists yet.

## Helpers

Paste these once in each new terminal. `task_times` prints the phase, start time and finish time of every task pod of a workflow, sorted by start time. `task_phases` prints the phase of every node, which includes skipped tasks.

```sh
task_times() {
  kubectl -n starfleet get workflow "$1" -o json | jq -r '.status.nodes[] | select(.type=="Pod") | [.startedAt, .displayName, .phase, .finishedAt] | @tsv' | sort
}
task_phases() {
  kubectl -n starfleet get workflow "$1" -o json | jq -r '.status.nodes[] | [.displayName, .type, .phase] | @tsv'
}
```

Use them like this: `task_times diamond-run`, `task_phases conditional-run`.

## Practice tasks

- Add a fifth task `docs` that depends on `build` only. Predict which tasks run in parallel, run it and compare your prediction with `task_times`.
- Make `lint` fail with `exit 1` and run the diamond with the default `failFast`. Then set `failFast: false` on the DAG and run it again. Write down which tasks started in each run.
- Write a task that uses `depends: package.Completed || test.Failed` and make `test` fail. Decide which result the workflow gets and why.
- Add `parallelism: 1` to a workflow and run the diamond. Explain why the total time grows although the dependencies are the same.
- Reference `{{tasks.version.outputs.parameters.version}}` from a task that does not depend on `version` and read what the controller reports.
