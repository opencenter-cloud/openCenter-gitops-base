---
id: docs-index
title: "openCenter-gitops-base Documentation"
sidebar_label: Documentation
description: Documentation index for the openCenter-gitops-base repository.
doc_type: explanation
audience: "platform engineers, operators, architects"
tags: [docs, index, navigation]
---

# openCenter-gitops-base Documentation

**Purpose:** For platform engineers, operators, and architects, explains how the openCenter-gitops-base documentation set is organized and where to look for each kind of task, covering getting started, day-2 operations, reference material, and concepts.

## What openCenter-gitops-base Provides

`openCenter-gitops-base` is a shared library of platform services deployed via FluxCD. It is consumed in two ways:

- Directly by cluster repositories that apply cluster-specific overrides.
- Indirectly by the private enterprise repository, which imports this base and applies private source, image, and values rewrites.

The repository covers two parts of the cluster lifecycle:

- `iac/` provisions the underlying infrastructure, renders Kubespray inventory and group variables, and initiates cluster bootstrap.
- `applications/` defines the reusable GitOps base for in-cluster platform services, observability components, and policy resources.

The authoritative service inventory and version table is maintained in the top-level [README](../README.md). For per-service detail, use the [Service Reference Library](reference/services/index.md).

## Documentation Layout

Documentation is organized by what the reader is trying to do, not by document genre. Each Markdown source has frontmatter declaring its `doc_type` (`tutorial`, `how-to`, `reference`, or `explanation`).

| Directory | Lifecycle stage | What lives here |
|-----------|-----------------|-----------------|
| [`getting-started/`](getting-started/) | Onboarding | First-deployment tutorial |
| [`operations/`](operations/) | Day-1 and day-2 tasks | Service onboarding, configuration, secrets, troubleshooting |
| [`reference/`](reference/) | Lookup | Directory layout, Flux resources, values schema, per-service reference |
| [`concepts/`](concepts/) | Understanding | Architecture, GitOps workflow, values layering, security model |
| [`release/`](release/) | Release notes | Per-release notes |
| [`contributing/`](contributing/) | Authoring | Templates for new service docs |

## Start Here

- [Getting Started with openCenter-gitops-base](getting-started/getting-started.md) – Deploy your first service end-to-end with FluxCD.
- [Architecture](concepts/architecture.md) – How `iac/` and `applications/` fit together and what this repository is not.
- [GitOps Workflow](concepts/gitops-workflow.md) – How FluxCD reconciles base content into a cluster.

## Operations

Service onboarding paths:

- [Service Deployment Patterns](operations/service-deployment-patterns.md) – Choose between community and enterprise sourcing.
- [Helm Service Onboarding](operations/helm-service-onboarding.md) – Onboard a Helm-based service.
- [OLM Service Onboarding](operations/olm-service-onboarding.md) – Onboard a service whose operator is installed through OLM.
- [Operator CR Service Onboarding](operations/operator-cr-service-onboarding.md) – Onboard services where Helm installs the operator and the cluster overlay creates the workload custom resources.
- [Add a Helm Service to the Community Repo](operations/add-helm-service-to-community-repo.md) – Add a shared service to `applications/base/services/`.

Cluster configuration and day-2:

- [Configure Helm Values](operations/configure-helm-values.md) – Combine base and override values.
- [Manage Secrets with SOPS](operations/manage-secrets.md) – Encrypt secrets for FluxCD reconciliation.
- [Configure Gateway API](operations/configure-gateway.md) – Set up ingress routing.
- [Set Up Observability](operations/setup-observability.md) – Deploy the monitoring stack.
- [Troubleshoot FluxCD](operations/troubleshoot-flux.md) – Debug reconciliation failures.
- [Service Version Upgrade Guide](operations/version-upgrade-guide.md) – Upgrade in-cluster services.
- [Add Disks to VMs](operations/add-disks-to-vms.md), [Add Windows Worker Nodes](operations/add-windows-nodes.md), [Replace a Control Plane Node](operations/replace-control-plane-node.md), [Resize Control Plane Nodes](operations/resize-control-plane-nodes.md).

Per-service operational guides live under [`operations/services/`](operations/services/index.md).

## Reference

- [Directory Structure](reference/directory-structure.md) – Repository layout.
- [Flux Resources](reference/flux-resources.md) – `GitRepository`, `HelmRelease`, `Kustomization` specs in this repo.
- [Helm Values Schema](reference/helm-values-schema.md) – Base values, override values, and merge behavior.
- [SOPS Configuration](reference/sops-configuration.md) – Secret encryption.
- [Service Reference Library](reference/services/index.md) – Per-service reference pages.

## Concepts

- [Architecture](concepts/architecture.md) – Repository boundaries and deployment flow.
- [GitOps Workflow](concepts/gitops-workflow.md) – Reconciliation model.
- [Base, Override, and Enterprise Values](concepts/three-tier-values.md) – Values layering rationale.
- [Enterprise Components Pattern](concepts/enterprise-components.md) – How the private enterprise repository composes on top of this base.
- [Security Model](concepts/security-model.md) – Security controls and known gaps.
- [OpenTelemetry Architecture](concepts/opentelemetry-architecture.md) – Telemetry pipeline overview.

## Infrastructure as Code

`iac/` has its own documentation set; start with the [`iac/` README](../iac/README.md) for cluster provisioning, Kubespray inventory generation, and the bootstrap flow.

## Contributing

Templates for new service documentation live in [`contributing/templates/`](contributing/templates/).
