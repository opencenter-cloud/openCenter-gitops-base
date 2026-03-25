---
id: service-rbac-manager
title: "rbac-manager"
sidebar_label: rbac-manager
description: Reference for the RBAC Manager service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, security teams"
tags: [rbac, access-control, operator]
---

# RBAC Manager

`rbac-manager` turns Kubernetes RBAC into a higher-level declarative workflow by reconciling `RBACDefinition` resources into bindings.

## What This Repo Deploys

- `Namespace/rbac-system`
- `HelmRelease/rbac-manager`
- Base values Secret: `rbac-manager-values-base`
- Optional override Secret: `rbac-manager-values-override`

## When to Use It

- Teams need consistent RBAC patterns across many namespaces.
- OIDC groups should map to reusable RBAC definitions rather than hand-written bindings.

## Example

```yaml
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
  name: read-only
```

## Configuration Surfaces

- Service path: `applications/base/services/rbac-manager/`
- Namespace: `rbac-system`
- Flux object: `HelmRelease/rbac-manager`
- Source: Fairwinds stable Helm repository

## Upstream References

- [RBAC Manager project](https://github.com/FairwindsOps/rbac-manager)
- [RBAC Manager chart](https://artifacthub.io/packages/helm/fairwinds-stable/rbac-manager)
