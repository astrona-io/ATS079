# DAG Dependencies, Conditional Tasks And Parallel Work (Playground)

- **Slug:** ats-079-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Argo Workflows v4.1.6 in the namespace `starfleet`, the service account `workflow-runner` and a `shuttle` client pod. No workflow exists. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-079-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting steps) |
| `bootstrap/01-install-argo-workflows.sh` | Installs Argo Workflows v4.1.6 as a namespaced install and removes the Argo server |
| `manifests/lab-start.yaml` | Namespace, shuttle client and the permissions of the workflow-runner service account |
| `docs/overview.md` | What the environment contains, helpers and ideas to try |
