# Overview: ApplicationSet Generators, Project Policy And Promotion (Playground)

This is a **playground**, not a lab. It starts a Git server and Argo CD and then waits. There is no task, no `astrona submit` and no pass or fail. Break things, repair them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- Gitea, a Git server, in the namespace `gitea`. The repository `starfleet/scout-deploy` holds a Kustomize `base` and the overlays `staging`, `production` and `preview`. Sign in as `platform` with the password `starfleet-gitops`. From your machine it is at `http://127.0.0.1:3000`. Inside the cluster it is at `http://gitea-http.gitea.svc:3000`.
- Argo CD 3.5.4 in the namespace `argocd`, at `https://127.0.0.1:8080` (accept the self-signed certificate). The notifications controller and Dex are scaled to zero. The ApplicationSet controller runs.
- The repository credentials for Argo CD. No project and no Application exist yet, so you create them.
- The namespaces `starfleet-staging`, `starfleet-production` and `starfleet-preview`, all empty. The overlays name image 6.14.0. Staging and preview have one replica, and production has two.
- `shuttle`, a client pod with `curl`, in the namespace `starfleet`.

## Helpers

Paste these once in each new terminal. `clone_deploy` clones the repository. `push_change` commits everything that changed in the clone and pushes it. `refresh` asks Argo CD to refresh an Application at once. `status` prints sync status, health status, project and revision of an Application.

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
  kubectl -n argocd get application "$1" -o jsonpath='sync={.status.sync.status} health={.status.health.status} project={.spec.project} revision={.status.sync.revision}{"\n"}'
}
```

Use them like this: `status scout-staging`, `refresh scout-staging`.

## Practice tasks

- Create an ApplicationSet with a Git directory generator for `overlays/*`, exclude `overlays/preview` and read the Applications it creates.
- Add a new folder `overlays/canary` to the repository and watch a new Application appear after the next read of the generator. Remove the folder and watch the Application go.
- Replace the generator with a matrix of the Git directory generator and a list of two names, and count the Applications.
- Create an AppProject with a role that may only sync, and a deny sync window for `*-production`. Read the windows and try a manual sync.
- Promote the image to 6.15.0 in `overlays/staging` only, in one commit, and compare the Deployments in staging and production.
