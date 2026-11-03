---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Policy Boundaries: Identity, Ownership And Rollback

An agent that can apply anything anywhere is a risk, so GitOps setups limit it. This part lists the four places where limits are set, shows what a violation looks like in Argo CD, explains who the cluster sees when the agent makes a change, how ownership of an object is recorded, and how a bad change is undone without losing the record of it.

## Four places where limits are set

1. **Git permissions.** Who may push to the branch that an Application tracks decides who may change the environment. Branch protection and review rules on the Git host turn a push into a reviewed change. This boundary is outside Argo CD, and it is the most important one: with pull delivery, the commit is the deployment.
2. **The AppProject.** Every Application belongs to exactly one project. The project lists the repositories that its Applications may read (`sourceRepos`), the destinations they may write to (`destinations`, each a cluster and a namespace), and which kinds of objects they may create (allow lists and deny lists for cluster-scoped and namespaced kinds). The project named `default` is created at installation and permits every repository, every destination and every kind. It is a starting point and not a boundary.
3. **Argo CD RBAC.** It decides which people may view, create, sync or delete Applications. It limits humans who use Argo CD and does not limit the controller.
4. **Kubernetes RBAC.** It limits the service account that the controller uses. The default installation grants that account broad permissions, so the project is what narrows the practical reach.

## What a violation looks like

The controller checks an Application against its project every time it compares. If the repository or the destination is not allowed, the controller does not apply anything. It records a condition on the Application with the type `InvalidSpecError` and a message that names the project. For a destination, the message has the form: application destination server and namespace do not match any of the allowed destinations in project. The Application stays in the cluster with its condition, which makes the refusal visible, and no object is created. The policy is enforced where the objects would be written, so a manifest that is accepted into Git is still not applied if the Application that delivers it is not allowed to.

## Identity: who made the change

When the controller applies an object, the Kubernetes API server records the caller as the service account of the controller. The cluster audit log therefore shows one identity for every change, and it does not show which person caused it. The person is recorded in Git: the author and the committer of the commit that was synced. To answer who changed this and why, read two records together: the cluster record says when the object changed and by which agent, and the Git record, found through the revision in `status.sync.revision`, says which commit and which author. This is a feature of the model: every change has a reviewed commit behind it, or the change did not come through the agent.

A change made by hand with `kubectl` shows the human identity in the audit log and the manager name `kubectl` in the `managedFields` of the object. That is the signal that an object was changed outside Git.

## Ownership

An object belongs to the Application whose tracking annotation it carries. The annotation value has the form `application:group/kind:namespace/name`. Argo CD uses it to find the objects of an Application, to decide what to prune and to show the resource tree. Two Applications that render the same object fight over it, and Argo CD reports a shared-resource warning. A project reduces this risk, because a destination limits which namespaces an Application may write to.

## Undoing a change

The history in Git is the record of the environment, so an undo must add to it. `git revert <commit>` creates a new commit that applies the opposite change. The old commit stays, the revert has its own author and time, and the agent delivers the revert as any other change. A forced push that removes the bad commit makes the record wrong: the cluster ran a state that the history no longer shows. A manual rollback inside Argo CD to an earlier sync, which is possible only while automated sync is off, changes the cluster and leaves Git on the bad commit, so a later sync would deploy the bad state again.

<!-- astrona:playground:renew -->
## Try it: a project that denies a destination

Create a project that allows one repository and the staging namespace only. Save this as `scout-team-project.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: scout-team
  namespace: argocd
spec:
  description: The scout team may deliver to staging only
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet-staging
```

Apply it:

```sh
kubectl apply -f scout-team-project.yaml
```

Check it: the project exists.

```sh
kubectl -n argocd get appproject scout-team
```

Now create an Application in that project that delivers the production overlay. Save this as `scout-production-attempt.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: scout-production-attempt
  namespace: argocd
spec:
  project: scout-team
  source:
    repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
    targetRevision: main
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet-production
  syncPolicy:
    automated: {}
    syncOptions:
      - CreateNamespace=true
```

Apply it:

```sh
kubectl apply -f scout-production-attempt.yaml
```

Check it: wait about 30 seconds, then read the conditions and look for the namespace.

```sh
kubectl -n argocd get application scout-production-attempt -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
kubectl get namespace starfleet-production
```

The Application has the condition `InvalidSpecError` with a message that names the project `scout-team`, and the command for the namespace answers that it was not found. The automated policy and `CreateNamespace` did not matter, because the project decided first. Now widen the project on purpose. Save this as `scout-team-project.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: scout-team
  namespace: argocd
spec:
  description: The scout team may deliver to staging and production
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet-staging
    - server: https://kubernetes.default.svc
      namespace: starfleet-production
```

Apply it and check the result:

```sh
kubectl apply -f scout-team-project.yaml
kubectl -n argocd annotate application scout-production-attempt argocd.argoproj.io/refresh=hard --overwrite
kubectl -n starfleet-production get deploy
```

After a short time the namespace exists and the Deployment `scout` runs there. The same Application, the same repository and the same commit were refused before and accepted now. Only the policy changed, and the change to the policy was an explicit edit of one object.

## Common pitfalls

> [!WARNING]
> The `default` project allows everything, so an installation that uses only `default` has no policy boundary. A project that lists `*` as a destination or repository is the same. Do not rely on Argo CD RBAC to limit the controller: it limits people. Never fix a bad release by deleting the commit from the history, and never leave a manual rollback in place while Git still holds the bad commit.
