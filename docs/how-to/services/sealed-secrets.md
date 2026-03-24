---
id: sealed-secrets-config-guide
title: "Sealed Secrets Configuration Guide"
sidebar_label: Sealed Secrets
description: How to use and configure Sealed Secrets in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [sealed-secrets, encryption, secrets, kubernetes]
---

# Sealed Secrets Configuration Guide

Use this guide when a cluster repo needs to manage encrypted secrets through the Sealed Secrets controller deployed from the base repo.

## What the Base Deploys

The base service deploys:

- `Namespace/sealed-secrets`
- `HelmRelease/sealed-secrets`
- base values from the service `helm-values/` directory
- optional `Secret/sealed-secrets-values-override`

The base does not create any `SealedSecret` application objects; those belong in the cluster repo.

## Typical Workflow

1. Fetch the cluster’s sealing certificate.
2. Generate a normal Secret locally.
3. Seal it into a `SealedSecret`.
4. Commit the sealed manifest to the cluster repo.

Example:

```bash
kubeseal --fetch-cert \
  --controller-name sealed-secrets \
  --controller-namespace sealed-secrets > sealed-secrets.crt
```

## Override Values Pattern

Use `sealed-secrets-values-override` only for controller-level changes such as resources or key renewal behavior.

## Operational Guidance

- Back up the controller keys if sealed secrets must survive cluster rebuilds.
- Be explicit about namespace scope when sealing secrets.
- Treat resealing as part of secret rotation or migration workflows.

## Verification

```bash
kubectl get helmrelease -n sealed-secrets sealed-secrets
kubectl get pods -n sealed-secrets
kubectl get sealedsecrets -A
kubectl describe sealedsecret <name> -n <namespace>
```

Healthy signs:

- controller Pod is `Running`
- `HelmRelease/sealed-secrets` is `Ready=True`
- `SealedSecret` resources reconcile into normal Kubernetes Secrets

## Common Failure Modes

Cannot decrypt after cluster rebuild:
- the controller key changed and old key material was not restored

SealedSecret never becomes a Secret:
- verify controller name, namespace, and sealing scope

`kubeseal --fetch-cert` fails:
- verify service reachability and correct controller namespace/name

## Related Docs

- [Sealed Secrets Service Reference](../../reference/services/sealed-secrets.md)
