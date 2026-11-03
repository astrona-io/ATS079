# Question

Solve this question on: `terminal`

The platform team wants Argo CD to find the environments of `scout` by itself. The Git repository `http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git` holds the folders `overlays/staging`, `overlays/production` and `overlays/preview`. The namespaces `starfleet-staging`, `starfleet-production` and `starfleet-preview` exist and are empty. No Application and no ApplicationSet exist. All Applications use the project `default`.

Reach Argo CD at `https://127.0.0.1:8080`.

1. Create the ApplicationSet `scout-folders` in the namespace `argocd`. It uses Go templates and one Git generator that reads the branch `main` of the repository above. The generator includes every folder below `overlays` and excludes `overlays/preview`.
2. The template creates an Application named `scout-<folder>` that delivers the folder from the branch `main` to the namespace `starfleet-<folder>` of the in-cluster server `https://kubernetes.default.svc`. Use the placeholders of the generator and do not write the folder names into the template.
3. The template turns on automated sync with `prune` and `selfHeal`. Wait until the Applications are healthy.

When you finish, these must be true:

- The ApplicationSet has exactly one generator, a Git directory generator for `overlays/*` with `overlays/preview` excluded, `goTemplate: true`, and placeholders in the name, the path and the namespace.
- The Applications `scout-staging` and `scout-production` are owned by the ApplicationSet. Both are `Synced` and `Healthy` at the head commit of `main`, and the Deployment `scout` runs `ghcr.io/stefanprodan/podinfo:6.14.0` with one ready replica in staging and two in production.
- No Application `scout-preview` exists and `starfleet-preview` holds no Deployment and no Service.
- The generated Applications have automated `prune` and `selfHeal`, and a hand edit of the replicas in production is undone.

`kubectl` already points at the cluster. Check your work with `astrona submit`.
