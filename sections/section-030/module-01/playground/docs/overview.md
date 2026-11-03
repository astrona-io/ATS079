# Overview: Build Artifacts, Notifications And Observable Delivery Contracts (Playground)

This is a **playground**, not a lab. It starts a Git server, Argo CD and a delivered staging environment, and then waits. There is no task, no `astrona submit` and no pass or fail. Break things, repair them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- Gitea, a Git server, in the namespace `gitea`. The repository `starfleet/scout-deploy` holds a Kustomize `base` and the overlays `staging` and `production`. Sign in as `platform` with the password `starfleet-gitops`. From your machine it is at `http://127.0.0.1:3000`. Inside the cluster it is at `http://gitea-http.gitea.svc:3000`.
- Argo CD 3.5.4 in the namespace `argocd`, at `https://127.0.0.1:8080` (accept the self-signed certificate). The notifications controller and Dex are scaled to zero, so no messages are sent. The ApplicationSet controller runs.
- The Application `scout-staging` with automated sync, pruning and self-heal. It delivers `overlays/staging` to the namespace `starfleet-staging`, with the image `podinfo` 6.14.0. The overlay `production` exists in Git, and no Application delivers it.
- `shuttle`, a client pod with `curl`, in the namespace `starfleet`.

## Helpers

Paste these once in each new terminal. `clone_deploy` clones the repository. `push_change` commits everything that changed in the clone with the message you give and pushes it. `refresh` asks Argo CD to refresh an Application at once. `delivery` prints the four facts of a delivery.

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
delivery() {
  kubectl -n argocd get application "$1" -o jsonpath='sync={.status.sync.status} health={.status.health.status} revision={.status.sync.revision} phase={.status.operationState.phase}{"\n"}'
}
```

Use them like this: `clone_deploy`, then edit a file, `push_change "message"`, `refresh scout-staging`, `delivery scout-staging`.

## Practice tasks

- Promote staging to 6.15.0 with a commit. Time how long the delivery takes with and without `refresh`.
- Push a commit that sets the tag `6.15.99`. Compare `delivery scout-staging` with the pods in `starfleet-staging`. Which signal turns bad first?
- Change the production overlay and observe that nothing happens, because no Application delivers it. Then create an Application for it.
- Scale `scout` in `starfleet-staging` by hand with `kubectl scale`. Observe how self-heal answers, and read `.status.history`.
- Write a delivery record as a ConfigMap and compare its commit with `git log --oneline`.
- Set `spec.syncPolicy.automated` to `null` on the Application, push a change and read the sync status. Start the sync by hand from the web page.
