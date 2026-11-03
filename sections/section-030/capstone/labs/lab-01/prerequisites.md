# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory.
- `kubectl`, `git`, `curl` and `jq`.
- You know what a Deployment, a ConfigMap and a Git commit are.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Gitea and Argo CD. It needs internet access to pull the images.
