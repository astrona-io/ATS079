# Build Artifacts, Notifications And Observable Delivery Contracts (Playground)

- **Slug:** ats-079-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35) with an in-cluster Git server (Gitea) holding the repository `starfleet/scout-deploy`, Argo CD 3.5.4, and the Application `scout-staging` delivering staging on 6.14.0. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-079-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting steps, port forwards) |
| `manifests/lab-start.yaml` | Namespace and the shuttle client pod |
| `bootstrap/` | Installs Gitea and Argo CD, seeds the repository, creates the Application |
| `repos/scout-deploy/` | The starting content of the Git repository |
| `docs/overview.md` | What the environment contains, helpers and ideas to try |
