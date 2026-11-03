# Solution

The task has three changes: set the rolling update fields on the blue Deployment, switch the Service selector to green and record the release. No image changes and nothing is deleted, so blue stays ready for a rollback.

## Step 1: set the strategy of blue

A patch changes only the strategy fields:

```sh
kubectl -n starfleet patch deploy scout-blue --type merge -p '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
```

The pod template does not change, so no new pods start. Check the fields:

```sh
kubectl -n starfleet get deploy scout-blue -o jsonpath='{.spec.strategy}{"\n"}'
```

## Step 2: switch the traffic

The Service sends traffic to the pods whose labels match its selector. Change the label `version` from `blue` to `green`:

```sh
kubectl -n starfleet patch service scout -p '{"spec":{"selector":{"app":"scout","version":"green"}}}'
```

Look at the endpoints and send a request from the client pod:

```sh
kubectl -n starfleet get endpoints scout
kubectl -n starfleet exec deploy/shuttle -- curl -s --max-time 5 http://scout/ | grep '"version"'
```

The endpoints list the two green pods, and the request shows version 6.15.0.

## Step 3: write the release record

The rollback command is the same patch with `blue` in the selector. Save this as `configmap-release-record.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-record
  namespace: starfleet
data:
  strategy: blue-green
  live: green
  previous: blue
  rollback: "kubectl -n starfleet patch service scout -p '{\"spec\":{\"selector\":{\"app\":\"scout\",\"version\":\"blue\"}}}'"
```

Apply it:

```sh
kubectl apply -f configmap-release-record.yaml
```

Run `astrona submit` to grade the result.
