---
draft: true
exam_objectives:
- CI/CD Relationship Fundamentals
---
# Summary

Continuous integration builds and checks every change and produces an artifact. Continuous delivery keeps every passing change ready to release, with a release decision. Continuous deployment removes the decision and releases every passing change. All three depend on one rule: the artifact that was tested is the artifact that runs. A tag can be moved, and a digest cannot, so an immutable reference is what ties the tested bytes to the deployed bytes, and provenance ties them to a source commit.

The delivery contract between CI and CD is small. CI hands over an artifact reference and a change in Git that names it. CD reads Git and changes the environment. With pull delivery, the build system holds no cluster credentials, so a compromised job can propose a bad change that is visible in the history and can be reverted, and it cannot reach into the cluster. A promotion is a commit, and a rollback is a revert. Writing the contract into Git makes each decision reviewable and each state reproducible.

Argo CD turns a commit into a change in steps. The repo-server renders the manifests of the path at a revision. The application controller compares them with the live objects, and with an automated policy it syncs the difference. The refresh is periodic, about every three minutes by default, or on request through an annotation or a webhook. The push of a commit therefore finishes the contract in Git, and the delivery follows later. The Deployment controller, and not Argo CD, performs the rolling update.

Signals differ in what they prove. Sync status says that the live objects match a revision, and `status.sync.revision` names the revision. Health status says that the objects work. A bad tag is applied as written, so the sync operation succeeds while health becomes `Degraded`. A green pipeline, a fresh `Synced` and a notification are all weaker than the pair of sync status and health at the commit that was pushed. A delivery record that stores the environment, version, commit and health makes the outcome readable later.

Key facts:

- A tag can move. A digest cannot.
- Pull delivery needs no cluster credentials in CI.
- A promotion is a commit and a rollback is a revert.
- Sync status and health status are independent.
- A notification is a prompt, not a source of truth.

<!-- astrona:playground:destroy -->
