---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# Repeatable Builds, Caching And Pinned Inputs

A pipeline earns trust when the same commit always gives the same result. A build that passes on Monday and fails on Tuesday for the same commit hides real failures, because the team learns to rerun until it turns green. The cause is almost always an input that changed without a commit.

This part lists the inputs that change silently, shows how to pin them, and explains how a cache makes a repeatable build fast without making it unreliable.

## Inputs that change without a commit

A build has more inputs than the source code. Each of these can change between two runs.

- The **base image** named in the container build file. A tag such as `alpine:latest` points to a new image after every release.
- The **dependencies** that the build downloads. A range such as `^2.1` accepts any newer 2.x version.
- The **tools** in the pipeline, for example a linter that the task installs at run time.
- The **pipeline images**, the containers that run each task.
- The **clock and environment**, for example a build that writes the current time into the output.

When one of them changes, the same commit builds a different artifact, and a failure appears with no matching change in Git.

## Pinning

To pin an input means to name an exact version of it. Pin the base image with a version tag at least, and with a digest when the build must be exactly repeatable. Pin dependencies with a lock file, a file that records the exact resolved version of every dependency, and commit the lock file. Pin the tools: install `linter 1.8.2`, not the newest linter. In the workflows of this course every task image carries a tag such as `alpine:3.23`, and the Kubernetes node image is `kindest/node:v1.35.8`, so a rerun uses the same software.

A pinned input changes only when a commit changes it. Teams automate that update: a bot opens a pull request that raises one pin, the pipeline tests the change like any other, and a person merges it. The pipeline stays repeatable, and the pins do not go stale.

## Caching

Downloading all dependencies on every run is slow. A cache stores them between runs. The rule that keeps a cache safe is that its key comes from the inputs. A cache key built from the hash of the lock file is valid exactly as long as the dependencies are the same. When the lock file changes, the key changes and the build starts with a fresh cache.

In Argo Workflows a cache is a PersistentVolumeClaim that outlives one run, mounted by the build task, or an object store that the task restores from and saves to. The example below uses the first variant. A workspace created with `volumeClaimTemplates` is deleted at the end of the run, so a cache needs a claim that you create yourself.

<!-- astrona:playground:renew -->
Save this as `pvc-build-cache.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: build-cache
  namespace: starfleet
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 64Mi
```

Apply it:

```sh
kubectl apply -f pvc-build-cache.yaml
```

Save this as `workflow-cache-run.yaml`. The task writes a marker file named after a cache key and reports whether the cache was already there:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: cache-run-
  namespace: starfleet
spec:
  entrypoint: build
  serviceAccountName: workflow-runner
  volumes:
    - name: cache
      persistentVolumeClaim:
        claimName: build-cache
  templates:
    - name: build
      container:
        image: alpine:3.23
        command: [sh, -c]
        args:
          - |
            key=deps-v1
            if [ -f /cache/$key ]; then echo "cache hit for $key"; else echo "cache miss for $key"; touch /cache/$key; fi
        volumeMounts:
          - name: cache
            mountPath: /cache
```

Create the workflow twice and read the logs of both runs:

```sh
kubectl create -f workflow-cache-run.yaml
kubectl create -f workflow-cache-run.yaml
kubectl -n starfleet get workflows
```

The first run reports a cache miss and creates the marker, and the second run finds the marker and reports a cache hit. If you change `key=deps-v1` to `key=deps-v2`, the next run misses again, which is the same behavior that a lock file hash gives in a real pipeline. Read the log of a run with `kubectl -n starfleet logs <pod name> -c main`, where the pod name appears in the output of `kubectl -n starfleet get pods`.

## What a cache must never hide

A cache is an optimization. A pipeline must give the same result with an empty cache, only slower. Test this from time to time by running one build without the cache. A build that passes only because stale files stay in the cache is not repeatable. Keep test output, secrets and build results out of a cache that several branches share.

## Summary of the habits

Build once for each commit. Name the artifact with a unique tag and record its digest. Pin every input. Key the cache by the inputs and allow the build to run without it. With these habits, a red pipeline means that the code changed, and a green pipeline means that the artifact is the one that was tested.

## Common pitfalls

> [!WARNING]
> A cache key that never changes keeps stale dependencies forever. A lock file that is not committed makes the build differ on every machine. A tag such as `latest` for a pipeline tool changes the pipeline without a commit. A cache that several branches share can pass one branch's files to another.
