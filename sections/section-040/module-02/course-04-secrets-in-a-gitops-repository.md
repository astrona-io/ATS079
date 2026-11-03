---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Secrets In A GitOps Repository

GitOps asks that everything be in Git, and secrets break that rule. A Kubernetes Secret only encodes its values with base64, which anyone can decode. A Secret committed to Git exposes the password to everyone who can read the repository, today and in every old commit. Deleting the file later does not remove it from the history.

This part explains the problem and the three common solutions, so that a repository can describe secrets without containing them.

## Why base64 is not protection

Kubernetes stores Secret values as base64 text. Base64 is an encoding for binary data and not encryption. Decoding it needs one command:

<!-- astrona:playground:renew -->
```sh
echo c3RhcmZsZWV0LWdpdG9wcw== | base64 -d
```

The command prints the original text `starfleet-gitops`. The same holds for every Secret in a manifest. Git history keeps old versions, so a leaked secret must be rotated, which means replaced with a new value, and not just deleted from the file.

## Option 1: encrypt the secret in Git

A tool encrypts the value before the commit, so Git holds only ciphertext.

- **Sealed Secrets** has a controller in the cluster with a private key. A command-line tool encrypts a Secret into a `SealedSecret` object with the public key. Only the controller can decrypt it, and it creates the real Secret in the cluster.
- **SOPS** encrypts the values in a YAML file with a key from a key management service or an age key. A plugin or the delivery tool decrypts the file when it renders manifests.

The encrypted file is reviewed and versioned like any other. The weak point is the key: whoever has it can read every secret, so the key is stored outside Git and backed up.

## Option 2: keep the secret outside Git

The repository holds a reference and a controller fetches the value from a secret manager such as a cloud key vault or HashiCorp Vault.

- **External Secrets Operator** defines an `ExternalSecret` object that names a store and a key. The operator reads the value from the store and creates a Kubernetes Secret, and it refreshes the Secret when the value changes.

Git holds only the name of the secret, never the value. Rotation happens in the secret manager, and access is controlled and logged there.

## Option 3: let the platform inject it

A tool such as the Secrets Store CSI driver mounts secrets from the manager into the pod as files, with no Kubernetes Secret object. This reduces the number of places that hold the value.

## Choosing

Encryption in Git is simple and works offline. A secret manager gives central rotation and audit logs. The choice follows what the organisation already runs. In all cases, three habits hold: no plain secret in Git, the decryption key or the store credentials outside the repository, and a rotation plan that runs without a deployment.

## The Argo CD side

Argo CD itself needs credentials to read private repositories. In the playground they are stored in a Secret in the `argocd` namespace with the label `argocd.argoproj.io/secret-type: repository`. List it:

```sh
kubectl -n argocd get secret -l argocd.argoproj.io/secret-type=repository
```

The command shows the Secret by name. The credential lives in the cluster, and not in the repository that it protects. Argo CD can also hide the values of Secrets in its web page, but anyone who can run `kubectl get secret` can still read them, so Kubernetes access control remains part of the protection.

## Pull and push

Because the cluster holds the credentials and the agent pulls from Git, the pipeline needs no cluster credentials. In a push model, the CI system runs `kubectl apply` or a deploy command, so it holds credentials for production and a breach of CI reaches the cluster. This is one security reason to prefer the pull model of GitOps.

## Common pitfalls

> [!WARNING]
> A deleted secret stays in Git history, so rotate it. Base64 text looks scrambled but is not encrypted. An encryption key stored in the same repository gives no protection. A Sealed Secret is bound to the cluster key, so restoring it into a new cluster needs the same key.
