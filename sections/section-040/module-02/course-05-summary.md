---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Summary

A GitOps repository holds the configuration of an application, apart from its source code. A base holds what is the same in every environment, and an overlay holds what differs. Kustomize renders the final manifests from them without templates, and `kubectl kustomize` shows the result before a commit. A single repository, a repository per environment or a repository per team are choices about who may change what.

Argo CD applies the rendered objects in one sync. Sync waves order normal objects, and Argo CD waits for the health of each wave before the next. Hooks run one-time Jobs at defined points: PreSync before the manifests, PostSync after health and SyncFail after a failure. A failed PreSync hook stops the sync, which protects the application from a failed migration. A delete policy removes old hook Jobs.

An Application has a sync status and a health status. The sync status compares Git with the live state, and the health status judges whether the objects work. Both must be read. The diff shows the fields that differ, and `ignoreDifferences` skips fields that another controller owns. Sync options such as `CreateNamespace`, `Prune=false`, `ServerSideApply` and `Replace` change how objects are applied.

A Secret is encoded, not encrypted, so a plain Secret must never be committed. Encrypted secrets in Git (Sealed Secrets, SOPS), references to a secret manager (External Secrets Operator) and injection by the platform are the usual solutions. A leaked secret is rotated, because Git history keeps it. The pull model also keeps cluster credentials out of the pipeline.

Key facts:

- Overlays state differences, and the base stays valid YAML.
- Sync wave numbers are strings, and lower waves run first.
- A PreSync hook must succeed before the sync continues.
- `Synced` and `Healthy` are separate statuses.
- Base64 is not encryption.

<!-- astrona:playground:destroy -->
