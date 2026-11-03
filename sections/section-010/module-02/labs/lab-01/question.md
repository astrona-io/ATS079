# Question

Solve this question on: `terminal`

The platform team builds the `scout` service with Argo Workflows in the namespace `starfleet`. Argo Workflows is installed and the service account `workflow-runner` exists. The pipeline must build once, hand the build output to a package task through a shared volume, and give delivery one exact image reference. Write it as a `WorkflowTemplate`, run it once and keep the result.

Create the `WorkflowTemplate` `build-pipeline` in `starfleet` with these properties:

1. The entrypoint is a DAG template named `pipeline`, and the pods run as the service account `workflow-runner`.
2. The workflow has two parameters: `version` with the default `1.4.0` and `commit` with the default `3f9c2ab`.
3. A `volumeClaimTemplates` entry named `work` requests 64Mi with the access mode `ReadWriteOnce`. Every task mounts it at `/work`.
4. The tasks are `build`, `package` and `deliver`, each using `alpine:3.23`. `package` depends on `build`, and `deliver` depends on `package`.
5. `build` writes the text `compiled-program` to the file `/work/app.bin`. `package` prints `/work/app.bin` with `cat` and publishes an output parameter named `image` whose value is `scout:` followed by the version, a dash and the commit, so `scout:1.4.0-3f9c2ab` with the defaults.
6. `deliver` takes the output parameter of `package` as its input parameter `image` and prints it.

Then create a `Workflow` named `build-run-1` in `starfleet` that uses the template `build-pipeline` with the default parameters. Wait until it finishes.

When you finish, these must be true:

- The template has the structure above.
- `build-run-1` finished with the phase `Succeeded`.
- The output parameter `image` of the `package` task is `scout:1.4.0-3f9c2ab`.
- The `deliver` task received that value as its input and all three tasks succeeded.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
