---
id: service-deployment-patterns
sidebar_label: Service Deployment Patterns
description: Explains how cluster repositories deploy services from the community repo or from the enterprise repo, and what belongs in each layer.
doc_type: how-to
title: "Service Deployment Patterns"
audience: "platform engineers, cluster operators"
tags: [cluster-repo, overlays, enterprise, fluxcd]
---

# Service Deployment Patterns

**Purpose:** For platform engineers and cluster operators, explains how cluster repositories should deploy services either directly from the community repo [openCenter-gitops-base](https://github.com/opencenter-cloud/openCenter-gitops-base) or through the private enterprise repo [opencenter-gitops-enterprise](https://github.com/opencenter-cloud/opencenter-gitops-enterprise) (private), while keeping cluster-specific data in the cluster repo. Detailed examples live in the deployment-model-specific onboarding guides.

## Index

- [Prerequisites](#prerequisites)
- [Overview](#overview)
- [Quick Comparison](#quick-comparison)
- [Repository Roles](#repository-roles)
- [Decision Rule](#decision-rule)
- [Shared Concepts](#shared-concepts)
- [Service Installation Models](#service-installation-models)
- [Choose By Deployment Model](#choose-by-deployment-model)
- [Community Deployment](#community-deployment)
- [Enterprise Deployment](#enterprise-deployment)
- [References](#references)

---

## Prerequisites

Before using either pattern, make sure:

- Flux is installed in the target cluster
- You have access to update the cluster overlay repo
- For enterprise deployments, the cluster repo also provides the required Git and registry credentials

---

## Overview

There are two supported service deployment patterns:

1. **Direct community deployment**
   The cluster repo points Flux directly at `openCenter-gitops-base//applications/base/services/<service>`.
2. **Enterprise deployment**
   The cluster repo points Flux at `opencenter-gitops-enterprise//applications/enterprise/services/<service>/overlays/install`, and that enterprise overlay imports the base service.

In both cases:

- The reusable service definition starts in `openCenter-gitops-base`
- The cluster repo owns cluster-specific overrides, secrets, and extra manifests
- Flux objects in the cluster repo control what gets deployed

Operationally, platform engineers should make service configuration changes in the **cluster overlay repo**. They are not expected to edit `openCenter-gitops-base` or `opencenter-gitops-enterprise` directly as part of normal service operations.

## Quick Comparison

| Scenario | Source repo | Flux path | Typical use |
| --- | --- | --- | --- |
| Community deployment | `openCenter-gitops-base` | `./applications/base/services/<service>` | Public upstream-backed service deployment |
| Enterprise deployment | `opencenter-gitops-enterprise` | `./applications/enterprise/services/<service>/overlays/install` | Private charts, private images, or enterprise-specific deltas |

---

## Repository Roles

The three repositories involved in service deployment have different responsibilities.

| Repository | Responsibility |
| --- | --- |
| Community repo | Provides reusable base service definitions and shared installation content |
| Enterprise repo | Imports community services and applies private chart, image, or enterprise-specific changes |
| Cluster overlay repo | Owns cluster-specific activation, overrides, secrets, credentials, and custom resources |

Platform engineers should make routine service changes in the **cluster overlay repo**.

If a shared baseline change is needed:

- Raise an issue in the community repo for shared community changes
- Raise an issue in the enterprise repo for shared enterprise changes

---

## Decision Rule

Use **direct community deployment** when:

- The service can run from public upstream artifacts
- No private chart source rewrite is required
- No private image rewrite is required
- No enterprise-only hardening or deltas are required

Use **enterprise deployment** when:

- The service must use private chart sources
- The service must use mirrored or private images
- Enterprise-specific hardened values must be applied
- Enterprise-only patches or source changes are required

---

## Shared Concepts

### Community Repo

[openCenter-gitops-base](https://github.com/opencenter-cloud/openCenter-gitops-base) provides reusable service definitions:

```text
applications/base/services/<service>/
```

### Enterprise Repo

[opencenter-gitops-enterprise](https://github.com/opencenter-cloud/opencenter-gitops-enterprise) is a private repository that provides install overlays which import base services and patch them:

```text
applications/enterprise/services/<service>/
├── components/enterprise/
├── enterprise/
└── overlays/install/
```

The install overlay typically imports:

```text
github.com/opencenter-cloud/openCenter-gitops-base//applications/base/services/<service>?ref=<ref>
```

and then applies enterprise-specific changes.

### Cluster Repo

The cluster repo owns:

- Flux `GitRepository` objects for service sources
- Flux `Kustomization` objects for installs
- Cluster-local values, secrets, custom resources, and extra manifests

Platform engineers should make service changes in the **cluster overlay repo** only.

Do not edit the service install content in `openCenter-gitops-base` or `opencenter-gitops-enterprise` as part of normal cluster operations.

If you need a change in the shared community or enterprise baseline, raise an issue in the corresponding repository so that change can be reviewed and implemented there.

### Sensitive Data

If cluster-local content includes sensitive data, such as passwords in Helm override values or Kubernetes `Secret` resources, make sure that content is encrypted with SOPS before it is committed.

This applies to examples such as:

- `helm-values/override-values.yaml` when it contains credentials or tokens
- `Secret` manifests for Git access, registry access, OCI access, or application credentials
- Any other cluster-local manifest containing confidential values

For the supported encryption pattern, see [SOPS Configuration](../reference/sops-configuration.md) and [Manage Secrets with SOPS](manage-secrets.md).

### Reconciliation Order

For both patterns, the expected reconciliation order is:

1. Apply the source object under `services/sources/`
2. Apply the service install `Kustomization` under `services/fluxcd/`
3. Apply the cluster-local overlay for service-specific values, secrets, and manifests

If the install `Kustomization` depends on sources or on a cluster-local overlay, keep those `dependsOn` relationships explicit.

---

## Service Installation Models

Services in this platform are not all installed the same way.

| Model | What installs the service | Typical cluster overlay responsibility | Examples |
| --- | --- | --- | --- |
| Helm-based | Flux reconciles a `HelmRelease` from the selected source repo | cluster-local Helm overrides and supporting manifests | `cert-manager`, `harbor`, `longhorn`, `metallb`, `loki` |
| OLM-based | Flux applies manifests that include `OperatorGroup` and `Subscription`, and OLM installs the operator | cluster-local patches and custom resources after the operator is ready | `keycloak` operator stage |
| Operator custom resources applied by Kustomize | the operator is installed separately, currently through Helm for services such as Kafka and PostgreSQL operators, and the cluster overlay applies the workload custom resources as normal manifests | custom resources such as database, Kafka, topic, or user definitions plus supporting Secrets | `postgresql`, `Kafka`, `KafkaTopic`, `KafkaUser` |

---

## Choose By Deployment Model

After selecting the source repo, choose the onboarding guide based on how the service is deployed:

| Deployment model | Use when | Guide |
| --- | --- | --- |
| Helm-based service | The base service is installed with `HelmRelease` and mainly customized through Helm values and supporting manifests | [Helm Service Onboarding](helm-service-onboarding.md) |
| OLM-based service | The base service includes resources such as `OperatorGroup` and `Subscription` | [OLM Service Onboarding](olm-service-onboarding.md) |
| Operator custom-resource workflow | The operator is installed with Helm and the cluster overlay needs to create workload custom resources such as `Kafka` or `postgresql` | [Operator CR Service Onboarding](operator-cr-service-onboarding.md) |

Examples in this repo:

- Helm-based: `cert-manager`, `harbor`, `longhorn`, `metallb`, `loki`, `tempo`
- OLM-based: `keycloak`
- Operator custom-resource workflow: `postgresql`, `Kafka`, `KafkaTopic`, `KafkaUser`

Use this page for source selection, ownership boundaries, and cluster overlay responsibilities. Use the deployment-model-specific guides for the actual onboarding steps.

---

## Community Deployment

Use this when the service can be installed from public artifacts.

---

## Enterprise Deployment

Use this when private charts, private images, or enterprise deltas are required.

The enterprise repo also requires cluster-specific access credentials when private Git, OCI charts, or private images are involved.

---

## References

- [Helm Service Onboarding](helm-service-onboarding.md)
- [OLM Service Onboarding](olm-service-onboarding.md)
- [Operator CR Service Onboarding](operator-cr-service-onboarding.md)
- [Enterprise Components Pattern](../explanation/enterprise-components.md)
- [Directory Structure Reference](../reference/directory-structure.md)
