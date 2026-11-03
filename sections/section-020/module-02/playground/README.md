# Detection: Signals, Alerts And Service Level Objectives (Playground)

- **Slug:** ats-079-playground-020-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with a healthy `scout` Deployment (two replicas) and its Service in the namespace `starfleet`, and a `shuttle` client pod. Nothing is broken. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-079-playground-020-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting steps) |
| `manifests/lab-start.yaml` | Namespace, shuttle client, healthy scout and its Service |
| `docs/overview.md` | What the environment contains, helpers and ideas to try |
