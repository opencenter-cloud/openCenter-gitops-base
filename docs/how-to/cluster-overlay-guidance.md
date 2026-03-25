---
id: cluster-overlay-guidance
sidebar_label: Cluster Overlay Guidance
description: Explains how cluster repositories should consume the base repo directly or through the private enterprise repo.
doc_type: how-to
title: "Cluster Overlay Guidance"
audience: "platform engineers, cluster operators"
tags: [cluster-repo, overlays, enterprise, fluxcd]
---

# Cluster Overlay Guidance

**Purpose:** For platform engineers and cluster operators, explains how cluster repositories should consume `openCenter-gitops-base` directly or indirectly through the private enterprise repo, while keeping cluster-specific data in the cluster repo.

## Overview

`openCenter-gitops-base` is the **base layer** for service definitions.

Cluster repositories should:

- point Flux either at the base service path in this repo or at the enterprise install overlay that imports this base
- keep cluster-specific overrides and runtime secrets in the cluster repo
- use the private enterprise repo for private source changes, private registry rewrites, and enterprise-only deltas

## Current Consumption Model

### Base-Only Consumption

If a service can install directly from upstream public artifacts, the cluster repo can reference the base service path directly:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  sourceRef:
    kind: GitRepository
    name: opencenter-gitops-base
  path: ./applications/base/services/cert-manager
  interval: 10m
```

### Enterprise Consumption

If private registry behavior, private chart sources, or enterprise-specific deltas are needed, the cluster repo should reference the **private enterprise repository install path**, not expect enterprise components inside this base repo.

That usually looks like:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  sourceRef:
    kind: GitRepository
    name: opencenter-gitops-enterprise
  path: ./applications/enterprise/services/cert-manager/overlays/install
  interval: 10m
```

## What the Cluster Repo Should Own

The cluster repo is the right place for:

- `*-values-override` Secrets
- cluster-specific hostnames and domains
- storage class choices
- dependency ordering between services
- service-level sealed secrets or SOPS-encrypted secrets
- additional patches for environment-specific behavior

It should not rely on hidden enterprise structure inside this base repo.

## Directory Expectations

### Base Repo

This repo provides:

```text
applications/base/services/<service>/
```

### Enterprise Repo

The private enterprise repo provides:

```text
applications/enterprise/services/<service>/
├── overlays/install/
└── ... enterprise-specific values, patches, or source rewrites as needed
```

The enterprise install overlay imports the base path from this repository and applies enterprise-specific deltas there.

### Cluster Repo

The cluster repo provides the service activation and cluster-specific data:

```text
applications/overlays/<cluster>/services/
├── sources/
│   └── opencenter-<service>.yaml
├── fluxcd/
│   └── <service>.yaml
└── <service>/
    ├── kustomization.yaml
    ├── helm-values/override-values.yaml
    └── cluster-specific secrets or manifests
```

## Recommended Overlay Patterns

### Pattern 1: Direct Base Consumption

Use this when:

- upstream sources are acceptable
- no private artifact rewrites are needed
- only cluster-specific override values are required

### Pattern 2: Enterprise Install Overlay

Use this when:

- the service must install from private chart sources
- mirrored/private images are required
- enterprise hardened values must be applied

This is the common enterprise-customer pattern:

1. The enterprise repo imports `openCenter-gitops-base`
2. The cluster repo points Flux at the enterprise install overlay
3. The cluster repo applies cluster-specific overrides and secrets in a second overlay

## Example: Enterprise Customer Flow

The cert-manager example you referenced follows this pattern.

### 1. Cluster repo defines a GitRepository for the enterprise repo

Example cluster repo file:

`applications/overlays/dev-cluster/services/sources/opencenter-cert-manager.yaml`

This is shown as a repo-relative example path rather than a clickable link because it belongs to the cluster repo, not to `openCenter-gitops-base`.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: opencenter-cert-manager-enterprise
  namespace: flux-system
spec:
  url: ssh://git@github.com/opencenter-cloud/opencenter-gitops-enterprise.git
```

### 2. Cluster repo installs the service from the enterprise repo

Example cluster repo file:

`applications/overlays/dev-cluster/services/fluxcd/cert-manager.yaml`

The `cert-manager-base` Flux `Kustomization` points to:

- source: `opencenter-cert-manager-enterprise`
- path: `./applications/enterprise/services/cert-manager/overlays/install`

That means the cluster is not installing directly from `openCenter-gitops-base`. It is installing from the enterprise repo, and that enterprise repo is responsible for importing and adjusting the base.

### 3. Cluster repo applies cluster-local overrides separately

The same file also defines a second Flux `Kustomization`, `cert-manager-override`, which points back to the cluster repo path:

- source: `flux-system`
- path: `./applications/overlays/dev-cluster/services/cert-manager`

This second layer is where cluster-specific data belongs.

### 4. Cluster-local directory holds the override Secret and extra manifests

Example cluster repo path:

`applications/overlays/dev-cluster/services/cert-manager`

The example cluster path contains:

- `kustomization.yaml`
- `helm-values/override-values.yaml`
- issuer manifests
- registry credentials
- OCI credentials
- other cluster-local secrets

Its `kustomization.yaml` generates the Secret expected by the base `HelmRelease`:

```yaml
secretGenerator:
  - name: cert-manager-values-override
    type: Opaque
    files: [override.yaml=helm-values/override-values.yaml]
    options:
      disableNameSuffixHash: true
```

This is the key architectural rule:

- base service definition lives in `openCenter-gitops-base`
- enterprise source and image changes live in `openCenter-gitops-enterprise`
- cluster-specific values and secrets live in the cluster repo

## Example: Adding Cluster Override Values

The base `HelmRelease` usually references an optional override Secret like:

```yaml
valuesFrom:
  - kind: Secret
    name: cert-manager-values-override
    valuesKey: override.yaml
    optional: true
```

A cluster repo can create that Secret in its own service overlay:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cert-manager-values-override
  namespace: cert-manager
type: Opaque
stringData:
  override.yaml: |
    replicaCount: 3
```

In practice, many cluster repos generate this Secret with `secretGenerator` instead of writing it inline as a raw Secret.

## Migration Checklist

If you still have older overlay assumptions, check the following:

- [ ] Overlay points at a real existing path in the chosen repo
- [ ] Base-only deployments reference `applications/base/services/<service>`
- [ ] Enterprise deployments reference the private enterprise install overlay
- [ ] Cluster-specific values are supplied by the cluster repo, not by editing the base or enterprise install overlay
- [ ] Flux has a separate path for service install and cluster-local override content when needed
- [ ] Flux `dependsOn` relationships still reflect service dependencies

## Testing

### Validate Base Path

```bash
kubectl kustomize applications/base/services/cert-manager
```

### Validate Enterprise Install Path

Run this from the private enterprise repo:

```bash
kubectl kustomize applications/enterprise/services/cert-manager/overlays/install
```

### Reconcile in Flux

```bash
flux reconcile source git opencenter-cert-manager-enterprise -n flux-system
flux reconcile kustomization cert-manager-base -n flux-system --with-source
flux reconcile kustomization cert-manager-override -n flux-system --with-source
```

## Troubleshooting

### Issue: Path Not Found

Check whether the cluster repo is pointing at:

- the base repo path
- or the enterprise repo install overlay

Do not point at historical `.../enterprise` paths inside `openCenter-gitops-base`.

### Issue: Override Secret Not Applied

Check:

- the Secret name matches the `HelmRelease.valuesFrom` reference
- the Secret is in the expected namespace
- the key name matches exactly, usually `override.yaml`

### Issue: Private Images or Private Charts Not Used

This usually means the cluster is consuming the base repo directly instead of the enterprise repo’s install overlay, or the enterprise repo is not patching the relevant source/image references.

## References

- [Enterprise Components Pattern](../explanation/enterprise-components.md)
- [Kustomize Patterns Reference](../reference/kustomize-patterns.md)
- [Directory Structure Reference](../reference/directory-structure.md)
