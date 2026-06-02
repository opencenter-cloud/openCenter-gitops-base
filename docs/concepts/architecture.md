---
id: architecture-explanation
title: "Architecture Explanation"
sidebar_label: Architecture
description: Architectural design, repository boundaries, and deployment flow behind the openCenter-gitops-base platform.
doc_type: explanation
audience: "architects, platform engineers"
tags: [architecture, gitops, fluxcd, kubespray, design]
---

# Architecture Explanation

**Type:** Explanation  
**Audience:** Architects, platform engineers  
**Last Updated:** 2026-03-31

This document explains the current architecture behind `openCenter-gitops-base`.

The important architectural point is that this repository is not a full cluster definition and not an enterprise overlay repository. It is the shared base used by those other layers.

---

## Overview

`openCenter-gitops-base` covers two parts of the platform lifecycle:

1. **Infrastructure bootstrap** in `iac/`
2. **Reusable in-cluster service definitions** in `applications/`

Those two areas solve different problems:

- `iac/` provisions infrastructure, renders Kubespray inputs, and drives Kubernetes cluster creation
- `applications/` defines the reusable GitOps base for platform services after the cluster exists

This repo is then consumed by:

- **cluster overlay repositories**, which decide what to install into a specific cluster
- the **private enterprise repo**, which imports the base services and applies enterprise-only patches, private sources, and private image rewrites

So the current openCenter architecture is best understood as a **multi-repository composition model**, not as a single repo containing every deployment layer.

## Design Philosophy

1. **GitOps-first service delivery**: in-cluster services are declared in Git and reconciled by Flux
2. **Separation of lifecycle stages**: cluster provisioning and in-cluster service delivery are related, but kept distinct
3. **Reusable public base**: shared services live here and stay upstream-backed
4. **Cluster-local ownership**: environment-specific activation, overrides, and secrets live in the consuming cluster repo
5. **Enterprise as an additive layer**: private enterprise deltas are applied outside this repository
6. **Pattern-based service authoring**: services follow a small set of repeatable Kustomize and Flux layouts

---

## Architecture Boundaries

### Repository Roles

The current architecture is split across three repository roles.

| Repository | Responsibility |
| --- | --- |
| `openCenter-gitops-base` | Shared infrastructure bootstrap code and reusable base service definitions |
| `opencenter-gitops-enterprise` | Private enterprise overlays, private chart/image rewrites, enterprise-only hardening |
| Cluster overlay repo | Cluster-specific Flux objects, service activation, secrets, override values, and local custom resources |

Routine operational changes usually belong in the **cluster overlay repo**, not in this repository.

### What This Repo Owns

This repository owns:

- Terraform or OpenTofu-driven cluster bootstrap inputs under `iac/`
- reusable service definitions under `applications/base/services/`
- shared policies under `applications/policies/`
- base Helm values and manifest composition
- upstream public chart or manifest sources for base services

### What This Repo Does Not Own

This repository does not own:

- cluster-specific Flux `GitRepository` and install `Kustomization` objects
- per-cluster hostnames, credentials, and environment overrides
- private enterprise chart sources or image rewrites
- per-service enterprise overlay trees

That separation is one of the key architectural decisions in the current platform model.

---

## End-to-End System View

### Lifecycle View

```text
Infrastructure inputs
  -> iac/
  -> Kubespray inventory and variables are rendered
  -> Kubernetes cluster is provisioned and bootstrapped

Cluster overlay repo
  -> defines Flux source and install objects for a specific cluster
  -> points at either:
     - openCenter-gitops-base
     - opencenter-gitops-enterprise

Flux in the cluster
  -> fetches the selected repo content
  -> applies Kustomize paths
  -> creates HelmRelease or manifest resources
  -> reconciles actual cluster state back to Git
```

### Repository Composition View

```text
                           +----------------------------------+
                           | cluster overlay repo             |
                           |----------------------------------|
                           | - source objects                 |
                           | - install kustomizations         |
                           | - override values                |
                           | - secrets and local manifests    |
                           +----------------+-----------------+
                                            |
                    chooses one install source |
                                            v
         +----------------------------------+----------------------------------+
         |                                                                     |
         v                                                                     v
+------------------------------+                          +----------------------------------+
| openCenter-gitops-base       |                          | opencenter-gitops-enterprise     |
|------------------------------|                          |----------------------------------|
| - iac/ bootstrap logic       |                          | - imports base service paths     |
| - base services              |                          | - patches sources/images/values  |
| - upstream public sources    |                          | - adds enterprise-only deltas    |
+---------------+--------------+                          +----------------+-----------------+
                |                                                                |
                +------------------------------+---------------------------------+
                                               |
                                               v
                                  +----------------------------------+
                                  | Flux controllers in cluster      |
                                  |----------------------------------|
                                  | Source -> Kustomize -> Helm      |
                                  +----------------+-----------------+
                                                   |
                                                   v
                                  +----------------------------------+
                                  | Kubernetes cluster state         |
                                  +----------------------------------+
```

---

## In-Cluster Delivery Architecture

### Flux Reconciliation Model

The service-delivery path in this platform is:

1. A cluster repo defines a Flux **source** object for the chosen repository and ref
2. A Flux **Kustomization** applies a service path from that repository
3. That path creates either:
   - a **HelmRelease**
   - plain manifests
   - operator-install resources plus later custom resources
4. Flux continuously reconciles those resources back to the declared Git state

For Helm-based services, the effective chain is:

```text
GitRepository -> Kustomization -> HelmRelease -> Helm chart install/upgrade
```

This matches the deployment model described in the GitOps and service deployment docs and is the core control-plane pattern for the `applications/` tree.

### Why Flux Sits in the Cluster Repo Layer

This base repo exports reusable install content, but it does not activate itself into a cluster. Activation happens when a consuming cluster repo creates the Flux objects that reference this repository.

That means:

- this repo is a **library of installable service paths**
- the cluster repo is the **deployment intent**
- Flux is the **reconciliation engine**

---

## Service Topology in This Repo

### Base Service Catalog

The main service library lives under:

`applications/base/services/`

Current service areas include:

- core services such as `cert-manager`, `harbor`, `headlamp`, `longhorn`, `metallb`, `sealed-secrets`, `velero`
- infrastructure integrations such as `openstack-ccm`, `openstack-csi`, `vsphere-csi`
- policy and access services such as `kyverno`, `rbac-manager`, `keycloak`
- operator-based platforms such as `postgres-operator` and `strimzi-kafka-operator`
- grouped service areas such as `observability/`
- multi-part service areas such as `istio/`

### Common Service Shapes

The architecture is intentionally pattern-based rather than forcing every service into one directory shape.

#### 1. Standard Helm-Based Service

Typical pattern:

```text
applications/base/services/<service>/
├── kustomization.yaml
├── namespace.yaml
├── source.yaml
├── helmrelease.yaml
└── helm-values/
    └── values-v<chart-version>.yaml
```

Examples include `cert-manager`, `harbor`, `metallb`, and `velero`.

#### 2. Manifest-Only Service

Some services are applied as plain manifests rather than through a `HelmRelease`.

Examples include:

- `external-snapshotter`
- `olm`

#### 3. Multi-Stage Service

Some services are intentionally broken into ordered stages because the installation is not a single chart release.

Example: `keycloak/`

```text
00-postgres/
10-operator/
20-keycloak/
30-oidc-rbac/
```

This reflects an architectural dependency chain:

- database first
- operator installation next
- workload custom resource after that
- supporting RBAC last

#### 4. Grouped Service Area

Some directories group related deployable services and shared resources.

Example: `observability/`

```text
observability/
├── namespace/
├── sources/
├── kube-prometheus-stack/
├── loki/
├── mimir/
├── opentelemetry-kube-stack/
└── tempo/
```

This is a grouped domain architecture, not a single monolithic service.

#### 5. Named Multi-Part Service

Some services are composed from named subdirectories instead of numbered stages.

Example: `istio/`

```text
istio/
├── namespace/
├── sources/
├── base/
├── istiod/
└── gateway/
```

This structure captures the fact that the service mesh installation has several coordinated components with shared sources and ordering requirements.

---

## Configuration and Values Architecture

### Value Ownership Model

The current platform does not treat all values as living in one repository.

Instead, values are split by ownership:

1. **Base values** live in `openCenter-gitops-base`
2. **Override values** live in the consuming cluster repo
3. **Enterprise values**, when needed, live in the private enterprise repo

For Helm-based services, Flux typically merges values in order through `valuesFrom`, with later entries overriding earlier ones.

### Why This Matters Architecturally

This split keeps responsibilities clear:

- shared defaults stay versioned with the base service
- cluster-specific differences stay local to the cluster
- enterprise-only hardening stays in the private repo

The architecture therefore optimizes for reuse and separation of ownership rather than for having every rendered value in one place.

---

## Deployment Models Supported

The base architecture supports more than one install model.

| Model | How the service is installed | Examples |
| --- | --- | --- |
| Helm-based | Flux reconciles a `HelmRelease` | `cert-manager`, `harbor`, `longhorn`, `metallb`, `loki`, `tempo` |
| Manifest-only | Flux applies plain manifests with Kustomize | `external-snapshotter`, `olm` |
| OLM-driven operator install | Flux applies `OperatorGroup` and `Subscription` resources and OLM installs the operator | `keycloak` operator stage |
| Operator plus workload CRs | an operator is installed first, then cluster repos apply workload custom resources | `postgres-operator`, `strimzi-kafka-operator`, `keycloak` workload stage |

This is why the service tree is not completely uniform: the directory layout follows the deployment mechanics.

---

## Key Architectural Decisions

### ADR-001: Separate Cluster Bootstrap From In-Cluster Service Delivery

**Decision:** Keep cluster provisioning logic in `iac/` and reusable in-cluster service delivery in `applications/`.

**Rationale:**

- provisioning and in-cluster operations have different lifecycles
- Kubespray bootstrap concerns should not be mixed with service reconciliation content
- teams can reason separately about cluster creation and post-bootstrap platform services

**Trade-offs:**

- architecture spans multiple tools and workflows
- operators need to understand where the IaC boundary ends and the GitOps boundary begins

### ADR-002: Treat This Repo As a Reusable Base, Not as a Cluster Repo

**Decision:** `openCenter-gitops-base` exports reusable service paths and base values, while cluster repos own activation and overrides.

**Rationale:**

- enables multiple clusters to consume the same base
- prevents per-cluster drift inside the shared repo
- keeps environment-specific secrets and tuning out of the reusable base

**Trade-offs:**

- understanding final state requires checking more than one repository
- operators must follow naming and layering conventions consistently

### ADR-003: Keep Enterprise Composition Outside the Base Repo

**Decision:** Private enterprise deltas belong in `opencenter-gitops-enterprise`, not inside base service paths.

**Rationale:**

- base stays public and upstream-backed
- private sources and mirrored images remain private
- enterprise logic stays additive instead of forking entire service definitions

**Trade-offs:**

- enterprise troubleshooting spans both base and enterprise repos
- version alignment between base and enterprise layers must be managed explicitly

### ADR-004: Use Pattern-Based Service Layouts Instead of Enforcing One Shape

**Decision:** Support several repeatable service structures: standard Helm services, manifest-only services, grouped domains, and staged services.

**Rationale:**

- real platform services do not all install the same way
- directory structure should reflect operational dependencies
- staged layouts make ordering visible in the repository itself

**Trade-offs:**

- the service tree is less visually uniform
- new contributors need to learn which pattern fits which service type

### ADR-005: FluxCD Is the In-Cluster Reconciliation Engine

**Decision:** Use Flux sources, Kustomizations, and HelmReleases as the control-plane model for service delivery.

**Rationale:**

- cluster state remains declarative and Git-driven
- drift can be detected and corrected automatically
- the same reusable service path can be consumed by multiple clusters

**Trade-offs:**

- debugging often requires following several controller layers
- reconciliation is not instantaneous

---

## Why This Architecture Works

The current architecture works because it preserves a clean contract between layers:

- `iac/` creates the cluster foundation
- this repo provides reusable service installation building blocks
- cluster repos decide what a specific cluster should run
- the enterprise repo adds private deltas only where required
- Flux continuously enforces the declared state inside the cluster

That gives openCenter a model that is:

- reusable across clusters
- compatible with both community and enterprise delivery
- explicit about ownership boundaries
- able to support different service installation patterns without duplicating full definitions

---

## Related References

- [GitOps Workflow](gitops-workflow.md)
- [Base, Override, and Enterprise Values](three-tier-values.md)
- [Enterprise Components Pattern](enterprise-components.md)
- [Service Deployment Patterns](../how-to/service-deployment-patterns.md)
- [Directory Structure Reference](../reference/directory-structure.md)
