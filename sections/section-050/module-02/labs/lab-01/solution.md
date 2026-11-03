# Solution

Step 1 writes the ApplicationSet, step 2 reads the generated Applications, and step 3 checks that Argo CD enforces Git. After each step, `astrona submit` shows which check passes.

## Step 1: Create the ApplicationSet

Save this as `scout-folders.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: scout-folders
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - git:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        revision: main
        directories:
          - path: overlays/*
          - path: overlays/preview
            exclude: true
  template:
    metadata:
      name: 'scout-{{ .path.basename }}'
    spec:
      project: default
      source:
        repoURL: http://gitea-http.gitea.svc:3000/starfleet/scout-deploy.git
        targetRevision: main
        path: '{{ .path.path }}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'starfleet-{{ .path.basename }}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

Create it:

```sh
kubectl apply -f scout-folders.yaml
```

Check it: run `astrona submit`. The check `applicationset-shape` passes.

## Step 2: Read the generated Applications

The generator reads the repository on a timer. List the Applications, and wait if the list is empty:

```sh
kubectl -n argocd get applications
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout-staging application/scout-production --timeout=300s
```

Two Applications exist, `scout-staging` and `scout-production`. The excluded folder `overlays/preview` has none. Check it: run `astrona submit`. The check `generated-applications` passes.

## Step 3: Check that Git is enforced

The template has `prune` and `selfHeal`, and the generated Applications copy them. The check `self-healing` scales production by hand and waits for Argo CD to undo it:

```sh
kubectl -n argocd get application scout-production -o jsonpath='{.spec.syncPolicy.automated}{"\n"}'
```

Run `astrona submit`. All three checks pass.

## Why this works

The generator turns the folders of the repository into parameter sets, and the template turns each set into an Application. The exclude entry keeps the preview folder out of the result. A new folder under `overlays` becomes a new Application on the next read, and the ApplicationSet owns every Application that it makes.
