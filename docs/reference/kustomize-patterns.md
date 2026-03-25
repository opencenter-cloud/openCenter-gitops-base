---
id: kustomize-patterns
title: "Kustomize Patterns Reference"
sidebar_label: Kustomize Patterns
description: Kustomize patterns and conventions used in openCenter-gitops-base for base service configuration.
doc_type: reference
audience: "platform engineers"
tags: [kustomize, patterns, kubernetes, gitops]
---

# Kustomize Patterns Reference

**Type:** Reference  
**Audience:** Platform engineers  
**Last Updated:** 2026-03-24

This document describes the Kustomize patterns used in `openCenter-gitops-base`.

This repository contains the **base service definitions only**. Those base definitions install charts and images from **upstream public sources**. Customer-specific or enterprise-specific repositories may reference this base and layer on overrides, such as:

- replacing `HelmRepository` sources with private registries or OCI repos
- overriding image registries, repositories, or tags
- adding cluster-specific secrets, patches, or extra resources

This repository does **not** model the enterprise overlay structure for each service. It provides the reusable base that external overlays build on.

---

## Kustomize Version

**Version:** v5.2+  
**API Version:** `kustomize.config.k8s.io/v1beta1`

---

## Base Service Patterns

There is no single directory shape for every service, but most services in this repository follow one of these patterns.

### Pattern 1: Helm-Based Single Service

This is the most common pattern.

```
applications/base/services/<service-name>/
├── kustomization.yaml
├── namespace.yaml
├── source.yaml
├── helmrelease.yaml
└── helm-values/
    └── values-<version>.yaml
```

Examples:

- `cert-manager`
- `gateway-api`
- `headlamp`
- `metallb`
- `postgres-operator`

### Pattern 2: Helm-Based Service with Extra Base Resources

Some services add storage classes, CRDs, or other manifests alongside the Helm release.

```
applications/base/services/<service-name>/
├── kustomization.yaml
├── namespace.yaml
├── source.yaml
├── helmrelease.yaml
├── helm-values/
│   └── values-<version>.yaml
└── extra manifests...
```

Examples:

- `longhorn` adds storage class manifests
- `vsphere-csi` includes optional CRD files

### Pattern 3: Manifest-Only Service

Some services are installed directly from upstream manifests or local YAML resources and do not use a HelmRelease.

```
applications/base/services/<service-name>/
├── kustomization.yaml
├── namespace.yaml
└── resources from local files or remote URLs
```

Examples:

- `external-snapshotter`
- `olm`

### Pattern 4: Multi-Stage Service

Some services are intentionally split into numbered directories so that cluster repositories can apply them as separate Flux Kustomizations with explicit ordering.

```
applications/base/services/<service-name>/
├── 00-<stage>/
├── 10-<stage>/
├── 20-<stage>/
└── 30-<stage>/
```

Examples:

- `keycloak`
- `istio`
- parts of `kyverno`

### Pattern 5: Shared Grouping Directory

Some top-level directories group related services rather than representing a single deployable unit.

Examples:

- `applications/base/services/observability/`
- `applications/base/services/global/`

These grouping directories may contain shared sources or namespace manifests, but they are not automatically a single “service” in the same way `cert-manager` or `harbor` are.

---

## Standard Helm Service Layout

For most base services, the kustomization follows a consistent structure:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - source.yaml
  - helmrelease.yaml

secretGenerator:
  - name: cert-manager-values-base
    namespace: cert-manager
    type: Opaque
    files:
      - values.yaml=helm-values/values-v<chart-version>.yaml
    options:
      disableNameSuffixHash: true
```

This pattern does three things:

1. creates the namespace
2. defines the upstream chart source
3. installs the chart through Flux with a generated Secret holding the base values

---

## Source Pattern

Base services in this repo point to **upstream sources**.

### Helm Repository Example

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: jetstack
spec:
  url: https://charts.jetstack.io
  interval: 1h
```

### OCI Helm Repository Example

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: envoyproxy
spec:
  url: oci://docker.io/envoyproxy
  interval: 1h
  type: oci
```

### What External Overlays Change

An enterprise or customer-specific repository can keep the same base service path and patch the source to use a private repository instead.

Typical overlay changes include:

- replacing `spec.url`
- changing `sourceRef.name`
- adding `secretRef` for OCI auth
- rewriting image registries inside Helm values

This repo does not carry those per-customer or enterprise patches.

---

## HelmRelease Pattern

Most Helm-based services follow this Flux pattern:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  interval: 5m
  timeout: 10m
  chart:
    spec:
      chart: cert-manager
      version: v<chart-version>
      sourceRef:
        kind: HelmRepository
        name: jetstack
        namespace: cert-manager
  valuesFrom:
    - kind: Secret
      name: cert-manager-values-base
      valuesKey: values.yaml
    - kind: Secret
      name: cert-manager-values-override
      valuesKey: override.yaml
      optional: true
```

### Values Tiers Used in This Base Repo

The base repo generally uses:

- `*-values-base`: generated from checked-in base values
- `*-values-override`: optional secret expected to be supplied by an overlay or cluster repo

The important detail is that the **base repo ships the required baseline**, while overlays provide optional environment-specific changes.

---

## Secret Generator Pattern

Helm values are commonly turned into Secrets via `secretGenerator` so Flux can consume them through `valuesFrom`.

### Basic Example

```yaml
secretGenerator:
  - name: cert-manager-values-base
    namespace: cert-manager
    type: Opaque
    files:
      - values.yaml=helm-values/values-v<chart-version>.yaml
    options:
      disableNameSuffixHash: true
```

### Why `disableNameSuffixHash` Is Used

Flux `HelmRelease.valuesFrom` references a stable Secret name. If Kustomize appended a content hash, the secret name would change and the HelmRelease reference would no longer match without additional wiring.

### Common Fields

| Field | Description |
|-------|-------------|
| `name` | Secret name referenced by the HelmRelease |
| `namespace` | Namespace where Flux expects the Secret |
| `type` | Usually `Opaque` |
| `files` | Key-to-file mapping inside the generated Secret |
| `options.disableNameSuffixHash` | Keeps the Secret name stable |

---

## Multi-Stage Service Pattern

Some services are not represented by a single top-level `kustomization.yaml`. Instead, they are split into deployment stages.

### Keycloak Example

```
keycloak/
├── 00-postgres/
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   └── postgres-cluster.yaml
├── 10-operator/
│   ├── kustomization.yaml
│   ├── operatorgroup.yaml
│   └── subscription.yaml
├── 20-keycloak/
│   ├── kustomization.yaml
│   └── keycloak-cr.yaml
└── 30-oidc-rbac/
    ├── kustomization.yaml
    └── default-rbac.yaml
```

### Istio Example

```
istio/
├── namespace/
├── sources/
├── base/
├── istiod/
└── gateway/
```

### Why This Pattern Exists

- different stages have different dependencies
- cluster overlays may want separate Flux `dependsOn` chains
- not all sub-parts are always applied in the same way

---

## Namespace Pattern

Most services define their own namespace explicitly.

### Simple Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
```

### Namespace with Security Labels

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: longhorn-system
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: privileged
```

The exact labels vary by service. Storage, networking, and infrastructure services often require more permissive namespace labels than application-facing services.

---

## Resource Ordering

Within a service kustomization, resources are usually listed in dependency order:

```yaml
resources:
  - namespace.yaml
  - source.yaml
  - helmrelease.yaml
```

When additional local manifests exist, they are typically placed before or alongside the Helm release depending on what the chart expects.

Examples:

- storage classes alongside `longhorn`
- source definitions before the Flux consumer object
- namespace first when namespaced resources are created

---

## Common Kustomization Fields Used Here

### `resources`

```yaml
resources:
  - namespace.yaml
  - source.yaml
  - helmrelease.yaml
```

### `secretGenerator`

```yaml
secretGenerator:
  - name: app-values-base
    namespace: app
    files:
      - values.yaml=helm-values/values-v<chart-version>.yaml
    options:
      disableNameSuffixHash: true
```

### `namespace`

Some kustomizations set a default namespace directly:

```yaml
namespace: harbor
```

This is used in some services instead of putting `namespace` on every resource.

---

## Overlay Expectations

This repository is intended to be consumed by other repositories.

### Typical Cluster Overlay Usage

A cluster repo usually points Flux at one of these base service paths:

```yaml
spec:
  path: ./applications/base/services/cert-manager
```

Then the cluster repo can add:

- override Secrets such as `cert-manager-values-override`
- ingress, DNS, or issuer resources
- environment-specific patches
- Flux dependency ordering across services

### Typical Enterprise Overlay Usage

An enterprise repo can reference the same base service path and layer on patches that switch installations from public upstream artifacts to private ones.

Typical enterprise overlay changes:

- replace upstream `HelmRepository` with private OCI or Helm repository
- rewrite image registry and repository settings
- add registry authentication secrets
- patch `HelmRelease.spec.chart.spec.sourceRef`

The key point is:

- **this repo owns the base deployment shape**
- **the enterprise repo owns private source and image overrides**

---

## Validation Commands

### Build a Base Service

```bash
kubectl kustomize applications/base/services/cert-manager
```

### Dry-Run Against a Cluster

```bash
kubectl kustomize applications/base/services/cert-manager | kubectl apply --dry-run=server -f -
```

### Validate with Kubeconform

```bash
kubectl kustomize applications/base/services/cert-manager | kubeconform -strict -
```

### Build a Multi-Stage Service Part

```bash
kubectl kustomize applications/base/services/keycloak/10-operator
```

---

## Best Practices

### File Organization

1. Put the namespace first when the service owns one.
2. Define the source before the `HelmRelease` that consumes it.
3. Keep versioned base values under `helm-values/`.
4. Split complex services into numbered or named stages when ordering matters.

### Naming Conventions

1. Use kebab-case for service directories.
2. Use versioned values filenames such as `values-v<chart-version>.yaml`.
3. Use stable Secret names such as `<service>-values-base`.
4. Keep filenames descriptive and aligned with the Flux object they support.

### Base vs Overlay Responsibility

1. Keep upstream/public defaults in this repo.
2. Keep private registry, private chart source, and tenant-specific changes outside this repo.
3. Do not encode customer-specific deployment assumptions into the base service paths.

---

## Troubleshooting

### Kustomization Build Fails

```bash
kubectl kustomize applications/base/services/cert-manager
```

Common issues:

- invalid YAML
- missing local files
- wrong relative paths
- bad remote manifest references

### Secret Not Generated

```bash
kubectl kustomize applications/base/services/cert-manager | grep -A 10 "kind: Secret"
```

Common issues:

- incorrect `files:` path
- missing `namespace`
- missing `disableNameSuffixHash`

### HelmRelease Does Not Resolve the Source

Check that:

- `source.yaml` exists in the rendered output
- `sourceRef.name` matches the generated source object
- the source namespace matches what the HelmRelease expects

### Overlay Does Not Replace the Upstream Source

If an external repo is patching the base:

- verify the patch target matches the rendered object name
- verify the overlay is applied after the base
- verify the patched `sourceRef` name matches the private source object

---

## Summary

`openCenter-gitops-base` uses Kustomize to define reusable, upstream-backed base services. The dominant pattern is a service kustomization with:

- namespace
- source
- HelmRelease or raw manifests
- generated base values Secret

More advanced deployment behavior such as private registries, private chart sources, and enterprise-specific artifact rewrites belongs in external overlays that consume this base rather than in the base repository itself.
