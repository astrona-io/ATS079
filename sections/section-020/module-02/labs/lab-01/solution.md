# Solution

The task is a first pass of an incident: list the pods, classify each failure by its status, read the exit code and write the facts down. Nothing in the cluster changes.

## Step 1: list the pods and read the status

Print the pods of the namespace:

```sh
kubectl -n starfleet get pods
```

The pod of `probe` shows a status such as `CrashLoopBackOff` and a growing `RESTARTS` count. The pod of `beacon` shows `Running` with `0/1` in the `READY` column, so it is alive but fails its readiness probe. The pods of `scout` show `Running` and `1/1`. If `probe` still shows `Error` and not `CrashLoopBackOff`, wait a few seconds and list again.

Read the events to confirm the reasons:

```sh
kubectl -n starfleet get events --sort-by=.lastTimestamp
```

The Warning events show `BackOff` for `probe` and a readiness probe failure for `beacon`.

## Step 2: read the exit code

Print the last exit code of the container of `probe`:

```sh
kubectl -n starfleet get pods -l app=probe -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
```

The command prints `3`, because the container runs `exit 3`. The log shows the line that the container wrote before it exited:

```sh
kubectl -n starfleet logs -l app=probe --tail=5
```

## Step 3: calculate the error budget

The window has 30 times 24 times 60, which is 43,200 minutes. The objective allows 0.1 percent failure, so the budget is 0.001 times 43,200, which is 43.2 minutes.

## Step 4: write the detection record

Save this as `configmap-detection-record.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: detection-record
  namespace: starfleet
data:
  crashing: probe
  exit-code: "3"
  not-ready: beacon
  healthy: scout
  error-budget-minutes: "43.2"
  severity: "3"
  signal: "The container status of probe shows exit code 3 and the event BackOff."
```

Apply it:

```sh
kubectl apply -f configmap-detection-record.yaml
```

Run `astrona submit` to grade the result.
