---
id: directory-structure
title: "Directory Structure Reference"
sidebar_label: Directory Structure
description: Directory structure of the openCenter-gitops-base repository and what each area is responsible for.
doc_type: reference
audience: "platform engineers, operators, architects"
tags: [directory, structure, repository, reference]
---

# Directory Structure Reference

**Type:** Reference  
**Audience:** All users  
**Last Updated:** 2026-04-01

This document describes the directory structure of `openCenter-gitops-base`.

This repository contains the **base service library**. It does not contain per-service enterprise components or private artifact overlays; those belong in the private enterprise repository.

## Repository Root

```text
openCenter-gitops-base/
├── .github/
├── applications/
├── docs/
├── iac/
├── playbooks/
├── README.md
└── ...
```

## Applications Directory

`applications/` contains the Kubernetes manifests that make up the base platform.

```text
applications/
├── base/
│   └── services/
└── policies/
```

### `applications/base/services/`

This is the main service catalog for the base repo.

Examples currently present include:

- `cert-manager/`
- `external-snapshotter/`
- `gateway-api/`
- `harbor/`
- `headlamp/`
- `istio/`
- `keycloak/`
- `kyverno/`
- `longhorn/`
- `metallb/`
- `observability/`
- `olm/`
- `openstack-ccm/`
- `openstack-csi/`
- `postgres-operator/`
- `rbac-manager/`
- `sealed-secrets/`
- `strimzi-kafka-operator/`
- `velero/`
- `vsphere-csi/`

### Service Layout Notes

Deployable paths under `applications/base/services/` are not all shaped the same way.

In practice, you will see a mix of:

- standard Helm-based service directories
- Helm-based services with extra manifests
- manifest-only service directories
- staged services such as `keycloak/`
- named multi-part services such as `istio/`

The architectural rationale for those shapes is explained in:

- [Architecture Explanation](../explanation/architecture.md)
- [GitOps Workflow](../explanation/gitops-workflow.md)

### Grouping Directories

Some directories group related services or shared resources and are not themselves a single deployable service.

Examples:

- `applications/base/services/observability/`

For example, `observability/` contains components such as:

- `kube-prometheus-stack/`
- `loki/`
- `mimir/`
- `opentelemetry-kube-stack/`
- `tempo/`
- `namespace/`
- `sources/`

## Managed Services

Managed services are not part of the public base repository layout. They belong in the private enterprise repository when they are required for a deployment.

## Policies

`applications/policies/` contains policy resources such as:

- network policies
- RBAC-related policy resources
- pod security or governance resources

## Docs

`docs/` contains repository documentation organized by Diataxis-style intent:

```text
docs/
├── explanation/
├── how-to/
├── reference/
├── templates/
├── tutorials/
└── *.md
```

Important references:

- `docs/reference/services/` for per-service reference pages
- `docs/explanation/enterprise-components.md` for the base-vs-enterprise repo relationship
- this page for current base service layout

## IaC

`iac/` contains the Infrastructure as Code used to create Kubernetes clusters.

This area is responsible for:

- collecting cluster inputs from Terraform or OpenTofu configuration
- provisioning the underlying infrastructure
- generating Kubespray inventory and Ansible variable files
- triggering Kubespray from Terraform or OpenTofu local provisioners to deploy the Kubernetes cluster

This is separate from `applications/`, which focuses on in-cluster platform services after the cluster exists.

Important paths:

- `iac/README.md`
- `iac/provider/kubespray/main.tf`
- `iac/provider/kubespray/hosts.tpl`

## Service-Level File Responsibilities

Typical files inside a Helm-based service directory:

- `namespace.yaml`: namespace definition
- `source.yaml`: upstream chart source such as `HelmRepository`
- `helmrelease.yaml`: Flux `HelmRelease`
- `kustomization.yaml`: base composition and `secretGenerator`
- `helm-values/values-v<version>.yaml`: base values file
- `README.md`: service-local documentation when present

## What Is Not In This Repo

This repo does **not** define per-service enterprise component directories or private enterprise values inside the base service paths.

It also does not carry private enterprise install overlays or private chart source rewrites for each service.

Those belong in the private enterprise repository, which imports the base service paths from this repository.

## Naming Conventions

- directories: kebab-case
- versioned values files: `values-v<chart-version>.yaml`
- Secret names: `<service>-values-base`, `<service>-values-override`
- Flux resource names: aligned with the service or chart name where practical

## File Organization Principles

1. Keep the base repo upstream-backed and reusable.
2. Keep service directories independently renderable where practical.
3. Split multi-stage services when deployment order matters.
4. Keep cluster-specific and enterprise-specific deltas outside this repo.

## References

- [Service Reference Library](services/index.md)
- [Enterprise Components Pattern](../explanation/enterprise-components.md)
