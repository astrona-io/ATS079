---
draft: true
exam_objectives:
- GitOps for Application Environments
---
# Summary

An ApplicationSet has a generator and a template. The generator decides which Applications exist. The list generator is the simplest. The cluster generator follows registered clusters. The Git directory generator turns folders into Applications, the Git file generator reads settings from files, and the pull request generator creates preview environments. The matrix generator combines two generators into every pair, and the merge generator overlays sets that share a key.

The Git directory generator uses `directories` with an include path such as `overlays/*` and optional entries with `exclude: true`. The template reads `.path.basename` and `.path.path`. The controller reads the repository on a timer, and a removed folder removes its Application. Go templates with `missingkey=error` catch misspelled keys.

An AppProject can also hold roles, sync windows and orphaned-resource monitoring. A role grants a narrow set of actions inside the project. A deny window blocks syncs at scheduled times, and a deny window wins over an allow window. Orphan monitoring reports unowned objects and never deletes them.

A promotion is a change in Git. Folders per environment are the common layout, branches add a merge gate with a risk of drift, and a pull request records approval. A safe promotion has a gate: staging is delivered and checked before production changes. Progressive syncs can order Applications inside one ApplicationSet.

Key facts:

- The generator decides which Applications exist; the template decides what they look like.
- `exclude: true` removes a folder from the matches.
- Removing a folder removes its Application.
- A deny sync window wins over an allow window.
- Orphaned resources are reported, not deleted.

<!-- astrona:playground:destroy -->
