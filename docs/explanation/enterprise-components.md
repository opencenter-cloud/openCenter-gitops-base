---
id: enterprise-components
sidebar_label: Enterprise Components
description: Explains how the private enterprise repository composes on top of openCenter-gitops-base and where enterprise components belong.
doc_type: explanation
title: "Enterprise Components Pattern"
audience: "platform engineers, architects"
tags: [enterprise, kustomize, architecture, overlays]
---

# Enterprise Components Pattern

**Purpose:** For platform engineers and architects, explains how the private enterprise repository composes on top of `openCenter-gitops-base`, and why those enterprise-specific deltas are not stored in this base repository.

## The Important Distinction

`openCenter-gitops-base` contains the **base service definitions only**.

Those base definitions:

- describe the reusable Kubernetes resources for each service
- reference **upstream public chart sources**
- use upstream/default image locations unless overridden elsewhere
- are intended to be consumed by other repositories

The **enterprise component pattern is not implemented inside this base repository**. It is implemented in the **private enterprise repository**, which imports this base and layers enterprise-specific deltas on top.

That means:

- the base repo owns the shared service definition
- the enterprise repo owns private registry/chart source overrides
- cluster repositories consume either the public base directly or the enterprise repo’s install overlay

## Why The Components Live in the Enterprise Repo

The enterprise-specific changes are not generic base behavior. They are edition-specific deltas such as:

- swapping an upstream `HelmRepository` for a private enterprise source
- adding enterprise-only hardened values
- injecting mirrored/private image settings
- wiring private registry or OCI authentication

Those changes are intentionally kept out of `openCenter-gitops-base` so the base remains:

- public
- upstream-backed
- reusable across community and enterprise consumers
- free of private registry or enterprise-only implementation details

## Repo Relationship

At a high level, the flow looks like this:

```text
openCenter-gitops-base
  -> defines base service manifests
  -> points to upstream public sources

openCenter-gitops-enterprise
  -> imports the base service path
  -> enables enterprise component(s)
  -> rewrites source/image settings to private enterprise artifacts

cluster repo
  -> points Flux at the desired install path
  -> adds environment-specific overrides and dependencies
```

## Concrete Example: cert-manager

In the base repo, `cert-manager` is defined as a normal base service under:

`applications/base/services/cert-manager`

That base service:

- defines the namespace
- defines the upstream `jetstack` Helm repository
- defines the `HelmRelease`
- generates the base values Secret

In the enterprise repo, the enterprise-specific logic lives under:

`applications/enterprise/services/cert-manager`

The path is shown as a repo-relative example, not a clickable link, because it lives in the private enterprise repo rather than in `openCenter-gitops-base`.

The relevant structure is:

```text
applications/enterprise/services/cert-manager/
└── overlays/
    └── install/
        └── kustomization.yaml
    ... plus enterprise-specific values, patches, and source definitions as needed
```

## What The Enterprise Overlay Does

The enterprise-specific layer for `cert-manager` does three key things:

1. adds the enterprise Helm source
2. removes the public upstream `HelmRepository`
3. patches the base `HelmRelease` to use the private source and enterprise values Secret

From the enterprise repo install path:

`applications/enterprise/services/cert-manager/overlays/install/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/opencenter-cloud/openCenter-gitops-base//applications/base/services/cert-manager?ref=<release/branch>
patches:
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2
      kind: HelmRelease
      name: cert-manager
    patch: |-
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: opencenter-cloud
```

It may also add enterprise-specific values, private source definitions, and mirrored image settings. The enterprise layer is not creating the service from scratch. It is modifying the base service imported from `openCenter-gitops-base`.

## How The Enterprise Repo Consumes The Base

The enterprise repo’s install overlay shows the intended composition model:

`applications/enterprise/services/cert-manager/overlays/install/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/opencenter-cloud/openCenter-gitops-base//applications/base/services/cert-manager?ref=<release/branch>
patches:
  - ...
```

This is the key architectural point:

- the base repo exports the reusable service path
- the enterprise repo imports that path
- the enterprise repo enables the component locally

## Base vs Enterprise Responsibilities

### Base Repository Responsibilities

`openCenter-gitops-base` is responsible for:

- shared service manifests
- upstream public `HelmRepository` or manifest source definitions
- base chart versions
- base values files
- reusable service structure

### Enterprise Repository Responsibilities

`openCenter-gitops-enterprise` is responsible for:

- enterprise hardened values
- private source definitions
- mirrored/private image overrides
- install overlays that combine base + enterprise deltas

## Why This Model Works

This split gives a cleaner separation of concerns than storing enterprise components inside the base repo.

**Public base stays clean**  
The base repo remains consumable on its own and does not need private registries, private OCI auth, or enterprise-only values files.

**Enterprise stays additive**  
The enterprise repo only stores the delta from base instead of duplicating full service definitions.

**Version alignment is explicit**  
The enterprise repo can pin to a specific base ref and keep its hardened values aligned to the corresponding chart/app version.

**Private implementation stays private**  
Private sources and private image rewrites are kept outside the public base repo.

## What This File Should Not Imply

This explanation should not imply that:

- per-service enterprise directories exist inside `openCenter-gitops-base`
- enterprise overlays are authored or consumed inside `openCenter-gitops-base`
- the base repo ships private image or chart source rewrites

Those patterns belong to the enterprise repo, not the base repo.

## Summary

Enterprise-specific overlays and patches are part of the overall openCenter enterprise model, but they are **not a base-repo implementation detail**.

In the current architecture:

- `openCenter-gitops-base` provides upstream-backed base service definitions
- `openCenter-gitops-enterprise` imports those base definitions
- enterprise components in the private repo patch the imported base to use private sources and enterprise values

That is the correct mental model for how enterprise composition works today.

## Evidence

- Base service example:
  [applications/base/services/cert-manager/](../../applications/base/services/cert-manager/)
- Enterprise install overlay example in the private enterprise repository:
  `applications/enterprise/services/cert-manager/overlays/install/kustomization.yaml`
