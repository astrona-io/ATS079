# Overview: Repository Layout, Sync Mechanics And Secrets (Playground)

This is a **playground**, not a lab. It starts a Git server, Argo CD and a staging Application, and then waits. There is no task, no `astrona submit` and no pass or fail. Break things, repair them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- Gitea, a Git server, in the namespace `gitea`. The repository `starfleet/scout-deploy` holds a Kustomize `base` and the overlays `staging` and `production`. Sign in as `platform` with the password `starfleet-gitops`. From your machine it is at `http://127.0.0.1:3000`. Inside the cluster it is at `http://gitea-http.gitea.svc:3000`.
- Argo CD 3.5.4 in the namespace `argocd`, at `https://127.0.0.1:8080` (accept the self-signed certificate). The notifications controller and Dex are scaled to zero. The ApplicationSet controller runs.
- The Application `scout-staging` in the project `default`. Its sync policy is `automated: {}`: new commits are delivered, hand edits are not undone and removed files are not pruned. It delivers `overlays/staging` (image 6.14.0, one replica) to `starfleet-staging`.
- The overlay `production` exists in Git, and no Application delivers it. The namespace `starfleet-production` does not exist.
- `shuttle`, a client pod with `curl`, in the namespace `starfleet`.

## Helpers

Paste these once in each new terminal. `clone_deploy` clones the repository. `push_change` commits everything that changed in the clone and pushes it. `refresh` asks Argo CD to refresh an Application at once. `status` prints sync status, health status and the policy of an Application.

```sh
clone_deploy() {
  git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/scout-deploy.git && cd scout-deploy
}
push_change() {
  git add -A && git -c user.name=ci -c user.email=ci@starfleet.local commit -m "$1" && git push origin main
}
refresh() {
  kubectl -n argocd annotate application "$1" argocd.argoproj.io/refresh=hard --overwrite
}
status() {
  kubectl -n argocd get application "$1" -o jsonpath='sync={.status.sync.status} health={.status.health.status} project={.spec.project} policy={.spec.syncPolicy.automated}{"\n"}'
}
```

Use them like this: `status scout-staging`, `refresh scout-staging`.

## Practice tasks

- Turn `automated` off with `kubectl -n argocd patch application scout-staging --type json -p '[{"op":"remove","path":"/spec/syncPolicy/automated"}]'`, push a commit and read the status. Start the sync from the web page.
- Turn on `selfHeal` and scale the Deployment by hand. Then add a HorizontalPodAutoscaler and observe the conflict over `replicas`.
- Add the annotation `argocd.argoproj.io/sync-options: Prune=false` to a ConfigMap in Git, remove it from Git with `prune` on, and observe that it stays.
- Create a project that lists only the staging namespace, move `scout-staging` into it and then change its path to `overlays/production`. Read the condition on the Application.
- Create a second Application that renders `overlays/staging` into the same namespace and read the shared-resource warning.
- Read `managedFields` of the Deployment after a `kubectl scale` and compare the manager names.
