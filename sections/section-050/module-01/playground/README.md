# Application Source, Destination And Project Boundaries (Playground)

- **Slug:** ats-079-playground-050-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35) with Gitea and Argo CD 3.5.4. The repository credentials exist, and no project and no Application exist. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-079-playground-050-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `manifests/lab-start.yaml` | Namespace and the shuttle client pod |
| `bootstrap/` | Installs Gitea and Argo CD, seeds the repository, adds the repository credentials |
| `docs/overview.md` | What the environment contains, helpers and ideas to try |
