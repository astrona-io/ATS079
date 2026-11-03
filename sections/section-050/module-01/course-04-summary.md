---
draft: true
exam_objectives:
- GitOps for Application Environments
---
# Summary

An Application ties one source to one destination. The source is a repository, a path and a revision. The destination is a cluster and a namespace. A revision that is a branch name follows the branch, and a revision that is a commit SHA is fixed, so a pinned Application ignores new commits until the pin is changed. The Application reports the commit that it compared in `status.sync.revision`, and that field is the proof of which version was delivered.

An AppProject limits a group of Applications. It lists the repositories that may be read, the destinations that may be written and the kinds that may be created. An Application that asks for something outside its project gets an `InvalidSpecError` condition, and nothing is applied. The default project allows everything, so each environment that matters belongs in a project that lists exactly its repository and its namespaces.

An object is tied to its Application by the tracking annotation `argocd.argoproj.io/tracking-id`, which holds the Application name, the group, the kind, the namespace and the name of the object. The tracking annotation is how the controller finds what it owns, and the finalizer `resources-finalizer.argocd.argoproj.io` decides what a deletion does. With the finalizer, deleting the Application deletes its objects first. Without it, only the Application is removed, and the objects keep running with no owner.

An ApplicationSet generates Applications from a template and a list of parameter sets. The generated Applications are owned by the ApplicationSet, and a hand edit to one of them is overwritten. Adding an element creates an Application, and removing an element deletes it, with the objects when the template carries the finalizer. Because one change reaches every environment, the ApplicationSet needs the same review as production.

Key facts:

- The source is a repository, a path and a revision. A SHA pins the Application.
- `status.sync.revision` names the commit that was compared.
- A project refusal is an `InvalidSpecError` condition, and it applies nothing.
- The finalizer `resources-finalizer.argocd.argoproj.io` makes a deletion cascade.
- Generated Applications are owned by the ApplicationSet, and removing an element removes the environment.

<!-- astrona:playground:destroy -->
