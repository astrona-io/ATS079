# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know what a pod, a namespace and a service account are.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Argo Workflows v4.1.6 in the namespace `starfleet`. The service account `workflow-runner` has the one permission that the executor needs. The lab needs internet access to download the Argo Workflows manifests.
