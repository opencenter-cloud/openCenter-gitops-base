---
id: values-layering
sidebar_label: Values Layering
description: Explains how base values, cluster overrides, and optional enterprise values are layered across the openCenter repositories.
doc_type: explanation
title: "Base, Override, and Enterprise Values"
audience: "platform engineers"
tags: [helm, values, overlays, enterprise]
---

# Base, Override, and Enterprise Values

**Purpose:** For platform engineers, explains how configuration is layered across the base repo, consuming cluster overlays, and the private enterprise repo.

## Why This Exists

Kubernetes platform services need a shared baseline, but clusters also need local differences such as hostnames, storage classes, replica counts, and environment-specific integrations.

If every cluster copied a full values file, upgrades would become expensive and error-prone. The base repo would drift from cluster repos, and small fixes would need to be repeated everywhere.

The openCenter model avoids that by separating responsibilities.

## The Current Layering Model

In practice, openCenter uses up to three value layers:

1. **Base values** in `openCenter-gitops-base`
2. **Override values** in the consuming cluster repository
3. **Enterprise values** in the private enterprise repository, when used

The important architectural point is that only the first layer lives in this repository by default.

## Base Values

Base values define the shared default behavior for a service:

- hardened defaults
- monitoring enablement
- common resource baselines
- chart settings that should be consistent for all consumers

Example location:

`applications/base/services/<service>/helm-values/values-v<chart-version>.yaml`

These values are usually turned into a Kubernetes Secret by the base service `kustomization.yaml`.

## Override Values

Override values are supplied by the repo that deploys the service into a real cluster.

They are the right place for:

- ingress hosts
- storage classes
- node selectors
- replica counts
- environment-specific endpoints
- cluster-specific integrations

The base service `HelmRelease` typically expects an optional Secret such as `cert-manager-values-override`, but the Secret itself is created outside this repo.

## Enterprise Values

Enterprise values are optional and belong to the private enterprise repo, not to `openCenter-gitops-base`.

That private repo may:

- import a base service path from this repo
- patch upstream chart sources to private repositories
- rewrite images to private registries
- add enterprise-only values or manifests

So the third layer exists in the broader platform model, but it is not part of the standard on-disk service layout in this repository.

## How Flux Sees the Layers

Flux merges `valuesFrom` entries in order. Later entries override earlier ones.

A typical base-repo `HelmRelease` looks like this:

```yaml
spec:
  valuesFrom:
    - kind: Secret
      name: cert-manager-values-base
      valuesKey: values.yaml
    - kind: Secret
      name: cert-manager-values-override
      valuesKey: override.yaml
      optional: true
```

An enterprise consumer may add a third source in its own repo, but that is not a requirement for base-only deployments.

## Why This Split Works

**Base stays reusable.**  
The base repo can remain public, upstream-backed, and easy to version.

**Cluster changes stay local.**  
Each cluster can express only the differences it needs.

**Enterprise deltas stay private.**  
Private registries, private charts, and enterprise-only settings do not have to leak into the public base repo layout.

## Trade-offs

**Indirection**  
To understand the final result, operators may need to inspect multiple repos.

**Naming discipline**  
The consuming repo must generate the override Secret names expected by the base `HelmRelease`.

**Merge behavior awareness**  
Helm merges maps, but lists are usually replaced. Overrides should be written carefully.

## When to Put a Change in Each Layer

Use **base values** for:

- defaults that should apply everywhere
- security posture
- baseline observability settings
- broadly correct resource settings

Use **override values** for:

- cluster-specific infrastructure differences
- environment-specific tuning
- local hostnames and integration endpoints

Use **enterprise values** for:

- private artifact rewrites
- enterprise-only behavior
- private-repo-specific hardening or integrations

## A Better Mental Model Than the Old "Three-Tier in One Repo" View

The older explanation implied that base, override, and enterprise values were all normal parts of the service tree in this repository.

That is not how the repo is used now.

The more accurate model is:

- this repo owns the **base**
- consuming cluster repos own **overrides**
- the private enterprise repo owns **enterprise-specific deltas**

## Related References

- [Configure Helm Values](../how-to/configure-helm-values.md)
- [Helm Values Schema](../reference/helm-values-schema.md)
- [Enterprise Components](enterprise-components.md)
