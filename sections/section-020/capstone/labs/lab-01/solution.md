# Solution

Three faults, three classes. Classify each pod from its status, fix the cause and not the symptom, and keep the evidence for the record.

## Step 1: classify the faults

Read the pods and their events first:

```sh
kubectl -n starfleet get pods
kubectl -n starfleet get events --sort-by=.lastTimestamp
```

Each failing pod shows a different mark:

- `scout` is in `ErrImagePull` or `ImagePullBackOff`. The event names the tag `6.15.99`, which does not exist. The container never ran.
- `probe` is in `CreateContainerConfigError`. The event says that the key `mode` is missing in the ConfigMap `probe-config`.
- `bridge` is `Running` with `0/1` ready. The event shows `Readiness probe failed` on port `9899`, and the application listens on `9898`.

## Step 2: repair scout

The image tag is the fault, and the Deployment has only one revision, so there is nothing to roll back to. Set the image to the healthy tag:

```sh
kubectl -n starfleet set image deploy/scout scout=ghcr.io/stefanprodan/podinfo:6.15.0
kubectl -n starfleet rollout status deploy/scout --timeout=120s
```

This writes a new pod template, which creates the revision 2.

## Step 3: repair probe

The ConfigMap is incomplete, so add the key. The Deployment is correct and must not change:

```sh
kubectl -n starfleet patch configmap probe-config --type merge -p '{"data":{"mode":"standard"}}'
kubectl -n starfleet rollout status deploy/probe --timeout=180s
```

The kubelet retries the container creation by itself, so the pod becomes ready without a restart of the Deployment.

## Step 4: repair bridge

The probe checks the wrong port. Save a patch that points it at the named port of the container.

Save this as `bridge-probe.yaml`:

```yaml
spec:
  template:
    spec:
      containers:
        - name: bridge
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
```

Apply it:

```sh
kubectl -n starfleet patch deploy/bridge --patch-file bridge-probe.yaml
kubectl -n starfleet rollout status deploy/bridge --timeout=120s
```

## Step 5: save the incident record

Save this as `incident-record.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: incident-record
  namespace: starfleet
data:
  severity: "2"
  status: resolved
  scout: "The release used an image tag that does not exist, so the pod could not pull its image."
  probe: "The ConfigMap probe-config had no key mode, so the container could not be created."
  bridge: "The readiness probe checked port 9899, so the pod never became ready and received no traffic."
  timeline: |
    three services down after the change window: image pull, config error, failing readiness
    set the scout image, added the key mode to probe-config, corrected the probe port of bridge
```

Apply it:

```sh
kubectl apply -f incident-record.yaml
```

Check it:

```sh
kubectl -n starfleet get deploy
kubectl -n starfleet get endpointslices
```

All three Deployments show `1/1` and every Service has a ready address.

## Common mistakes

- Deleting and recreating a Deployment. The grader checks the revision number of `scout` and `bridge`.
- Removing the `MODE` variable from `probe`, which hides the missing configuration key.
- Removing the readiness probe from `bridge`, which makes the pod ready without checking anything.
- Using the word `config` in the record where the grader reads `ConfigMap`, or leaving out the word `readiness`.
