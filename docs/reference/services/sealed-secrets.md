---
id: service-sealed-secrets
title: "sealed-secrets"
sidebar_label: sealed-secrets
description: Reference for the Sealed Secrets service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [secrets, gitops, encryption]
---

# Sealed Secrets

`sealed-secrets` allows encrypted secret manifests to be committed to Git while only being decryptable by the controller running inside the target cluster.

## What This Repo Deploys

- `Namespace/sealed-secrets`
- `HelmRelease/sealed-secrets`
- Base values Secret: `sealed-secrets-values-base`
- Optional override Secret: `sealed-secrets-values-override`

## When to Use It

- You need Git-safe secret storage in cluster repositories.
- You want workloads to consume normal Kubernetes Secrets while keeping encrypted manifests in Git.
- You want a simpler encrypted-secret workflow than external secret managers for some use cases.

## Key Integration Points

- Cluster repos create `SealedSecret` resources.
- Controller keys are cluster-specific and must be backed up if you rely on disaster recovery.

## Example

```bash
kubectl create secret generic app-creds \
  --from-literal=password=change-me \
  --dry-run=client -o json \
| kubeseal --format yaml > app-creds-sealed.yaml
```

## Configuration Surfaces

- Service path: `applications/base/services/sealed-secrets/`
- Namespace: `sealed-secrets`
- Flux object: `HelmRelease/sealed-secrets`
- Base values Secret: `sealed-secrets-values-base`
- Override values Secret: `sealed-secrets-values-override`

## Related Docs

- [Sealed Secrets Configuration Guide](../../how-to/services/sealed-secrets.md)

## Upstream References

- [Sealed Secrets project](https://github.com/bitnami-labs/sealed-secrets)
- [Sealed Secrets docs](https://github.com/bitnami-labs/sealed-secrets#readme)
- [Helm chart reference](https://artifacthub.io/packages/helm/bitnami-labs/sealed-secrets)
