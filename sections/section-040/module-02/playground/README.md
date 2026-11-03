# Managed Runtimes, Agents And Policy Boundaries (Playground)

- **Slug:** ats-079-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35) with Gitea, Argo CD 3.5.4 and the Application `scout-staging` with the sync policy `automated: {}`. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-079-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `manifests/lab-start.yaml` | Namespace and the shuttle client pod |
| `bootstrap/` | Installs Gitea and Argo CD, seeds the repository, creates the Application |
| `docs/overview.md` | What the environment contains, helpers and ideas to try |
