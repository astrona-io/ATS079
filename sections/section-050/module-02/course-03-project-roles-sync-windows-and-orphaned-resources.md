---
draft: true
exam_objectives:
- GitOps for Application Environments
---
# Project Roles, Sync Windows And Orphaned Resources

An AppProject limits where its Applications may deliver. It can also limit who may act on them, and when. This part adds three features: project roles, sync windows and orphaned-resource monitoring.

## Project roles

A **project role** is a named set of permissions that is valid inside one project. A role has policies in the form of the Argo CD access rules, and it can have tokens for automation.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: scout-team
  namespace: argocd
spec:
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet-staging
  roles:
    - name: deployer
      description: Can sync Applications of this project
      policies:
        - p, proj:scout-team:deployer, applications, get, scout-team/*, allow
        - p, proj:scout-team:deployer, applications, sync, scout-team/*, allow
```

A policy line has the form `p, subject, resource, action, object, effect`. The subject `proj:scout-team:deployer` is the role. The object `scout-team/*` means every Application in the project. This role may read and sync, and it may not create, delete or change an Application. A role can be bound to groups from a single sign-on system with the `groups` field.

## Sync windows

A **sync window** allows or denies syncs at a time. It is part of the project.

```yaml
spec:
  syncWindows:
    - kind: deny
      schedule: '0 22 * * *'
      duration: 8h
      applications:
        - '*-production'
      manualSync: false
```

The schedule is in cron form, and the duration is the length of the window. This `deny` window blocks syncs of Applications that match `*-production` from 22:00 for eight hours. With `manualSync: false`, a manual sync is blocked too. An `allow` window works the other way: syncs are allowed only inside it, and outside it they are blocked. A deny window wins over an allow window. A window also has a `timeZone` field; without it the time is UTC.

Sync windows do not stop Git from changing. They stop the sync, so the Application shows `OutOfSync` until the window ends.

## Orphaned resources

An **orphaned resource** is an object in a namespace that an Application delivers to, which no Application owns. It may be a leftover from a hand edit or from an old release. Turn on monitoring in the project:

```yaml
spec:
  orphanedResources:
    warn: true
```

With `warn: true`, Argo CD shows a condition on the Application for each orphan and does not change the health. Argo CD never deletes orphans on its own, so removal is a decision.

## Apply and read it

<!-- astrona:playground:renew -->
Save the project above (with the sync window and `orphanedResources` added) as `scout-team.yaml`, and set the destination namespace to one that exists in the playground. Apply and read the result:

```sh
kubectl apply -f scout-team.yaml
kubectl -n argocd get appproject scout-team -o jsonpath='{.spec.syncWindows[*].kind}{"\n"}{.spec.roles[*].name}{"\n"}'
```

The output shows `deny` and `deployer`. Read the active windows of the project from the command line tool with `argocd proj windows list scout-team`.

## Common pitfalls

> [!WARNING]
> A deny window that matches the Application you need to repair blocks the repair too, so use `manualSync: true` for a way out. A cron schedule without `timeZone` runs in UTC. A role with `applications, *` allows every action. Orphan monitoring does not delete anything; it only reports.
