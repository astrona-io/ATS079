# Overview: Stages, Shared Workspaces And Image Identity (Playground)

This is a **playground**, not a lab. It starts a cluster with Argo Workflows and waits. There is no task, no `astrona submit` and no pass or fail. Write workflows, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it. You need `jq` on your machine to read workflow status.
- **Argo Workflows v4.1.6**, installed into the namespace `starfleet`. The workflow controller watches only that namespace. The Argo server (web page and API) is not installed, so you work with `kubectl`.
- The service account `workflow-runner` in `starfleet`. It has one Role that lets the executor write task results. Set `serviceAccountName: workflow-runner` in every workflow you write.
- `shuttle`, a client pod with `curl`, in `starfleet`.
- No `WorkflowTemplate` and no `Workflow` exists yet.

## Helpers

Paste this once in each new terminal. `task_outputs` prints the output parameters of every task of a workflow.

```sh
task_outputs() {
  kubectl -n starfleet get workflow "$1" -o json | jq -r '.status.nodes[] | select(.outputs.parameters != null) | [.displayName, (.outputs.parameters[] | .name + "=" + .value)] | @tsv'
}
```

Use it like this: `task_outputs image-ref-run`.

## Practice tasks

- Add a `volumeClaimTemplates` workspace to a workflow, write a file in one task and read it in the next. Remove the `volumeMounts` from the second task and read the error.
- Write a task that creates the file `/tmp/image.txt` with an image reference and publish it as an output parameter. Pass it to a second task.
- Run two parallel tasks that write the same file on a shared workspace. Then give each task its own directory.
- Create a PVC named `build-cache` and run a workflow twice that uses it. Change the cache key and run it again.
