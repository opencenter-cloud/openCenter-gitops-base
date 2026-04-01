---
id: docs-index
sidebar_label: Documentation
description: Primary documentation index for openCenter-gitops-base.
doc_type: overview
title: "openCenter-gitops-base Documentation"
audience: "platform engineers, operators, architects"
tags: [docs, index, navigation]
---

# openCenter-gitops-base Documentation

**Purpose:** For all audiences, provides navigation to documentation for deploying and managing production-ready Kubernetes platform services using FluxCD GitOps.

## What is openCenter-gitops-base?

openCenter-gitops-base is a centralized library of production-ready, security-hardened Kubernetes platform services deployed via GitOps. It provides 22+ core services and a complete observability stack that form the foundation of openCenter Kubernetes clusters.

**Key characteristics:**
- **GitOps-native:** All services deployed and managed via FluxCD
- **Security-hardened:** Production-ready configurations with security best practices
- **Standardized:** Consistent deployment patterns across all services
- **Customizable:** Base values in this repo with optional overrides supplied by consuming overlays
- **Observable:** Complete monitoring, logging, and tracing stack included
- **Provisionable:** `iac/` provisions infrastructure, renders Kubespray inputs, and triggers Kubernetes installation through Kubespray

The authoritative service and version inventory is maintained in the top-level [README](../README.md). For deeper per-service documentation, use the [Service Reference Library](reference/services/index.md).

## Infrastructure and Services

This repository supports both parts of the openCenter cluster lifecycle:

- **Infrastructure as Code** under [`iac/`](../iac/README.md) provisions the underlying infrastructure, renders Kubespray inventory and group variables, and initiates Kubernetes cluster deployment through Kubespray
- **GitOps base services** under `applications/` provide the reusable service definitions that cluster repositories can consume directly, or that the private enterprise repo can import and extend

## How This Repository Fits in the Ecosystem

openCenter-gitops-base is one component of the larger openCenter platform:

- **openCenter-cli** generates cluster repositories that reference this base repository
- **Cluster deployments** install services by pointing FluxCD at specific paths in this repository or in the private enterprise repo that imports it
- **Base configurations** are customized via overlays in cluster repositories
- **Infrastructure as Code** under `iac/` provisions the underlying cluster hosts and runs Kubespray
- **Private enterprise repositories** can import this base and apply enterprise-specific source and image overrides
- **Version pinning** via Git tags ensures reproducible deployments

For the complete repo architecture described here, see [Architecture Overview](explanation/architecture.md).

## Quick Start by Role

### New to openCenter?

- [Infrastructure as Code](../iac/README.md)
- [Getting Started Tutorial](tutorials/getting-started.md)

Use the IaC guide to build a cluster, then follow the tutorial to deploy your first service (cert-manager) and understand the GitOps workflow.

### Platform Engineers

- [Add a Helm Service to the Community Repo](how-to/add-helm-service-to-community-repo.md) - Add a new shared Helm-based service to the community repo
- [Service Deployment Patterns](how-to/service-deployment-patterns.md) - Choose community versus enterprise sourcing and the right deployment model
- [Helm Service Onboarding](how-to/helm-service-onboarding.md) - Onboard Helm-based services into a cluster overlay repo
- [OLM Service Onboarding](how-to/olm-service-onboarding.md) - Onboard services whose operator is installed through OLM
- [Operator CR Service Onboarding](how-to/operator-cr-service-onboarding.md) - Onboard services where Helm installs the operator and the cluster overlay creates the workload custom resources
- [Configure Helm Values](how-to/configure-helm-values.md) - Customize service configuration
- [Manage Secrets with SOPS](how-to/manage-secrets.md) - Encrypt sensitive data
- [Troubleshoot Flux](how-to/troubleshoot-flux.md) - Debug reconciliation issues
- [Configure Gateway API](how-to/configure-gateway.md) - Set up ingress routing
- [Setup Observability](how-to/setup-observability.md) - Deploy monitoring stack

Reference:
- [iac/ README](../iac/README.md) - Cluster provisioning, Kubespray inventory generation, and bootstrap flow
- [Service Reference Library](reference/services/index.md) - Per-service reference pages
- [Directory Structure](reference/directory-structure.md) - Repository layout
- [Flux Resources](reference/flux-resources.md) - GitRepository, HelmRelease, Kustomization specs
- [Helm Values Schema](reference/helm-values-schema.md) - Base values, override values, and merge behavior
- [SOPS Configuration](reference/sops-configuration.md) - Secret encryption

### Architects and Decision Makers

- [Architecture Overview](explanation/architecture.md) - System design and decisions
- [GitOps Workflow](explanation/gitops-workflow.md) - How FluxCD manages deployments
- [Base, Override, and Enterprise Values](explanation/three-tier-values.md) - Configuration layering rationale
- [Enterprise Components](explanation/enterprise-components.md) - How the private enterprise repo composes on top of base
- [Security Model](explanation/security-model.md) - Security controls and gaps

## Documentation Structure

Use these sections based on what you need:

### Tutorials
- [Getting Started](tutorials/getting-started.md) - Deploy your first service

### How-To Guides
- [Add a Helm Service to the Community Repo](how-to/add-helm-service-to-community-repo.md)
- [Service Deployment Patterns](how-to/service-deployment-patterns.md)
- [Helm Service Onboarding](how-to/helm-service-onboarding.md)
- [OLM Service Onboarding](how-to/olm-service-onboarding.md)
- [Operator CR Service Onboarding](how-to/operator-cr-service-onboarding.md)
- [Configure Helm Values](how-to/configure-helm-values.md)
- [Manage Secrets with SOPS](how-to/manage-secrets.md)
- [Configure Gateway API](how-to/configure-gateway.md)
- [Setup Observability](how-to/setup-observability.md)
- [Troubleshoot Flux](how-to/troubleshoot-flux.md)

### Reference
- [Directory Structure](reference/directory-structure.md)
- [Service References](reference/services/index.md)
- [Flux Resources](reference/flux-resources.md)
- [Helm Values Schema](reference/helm-values-schema.md)
- [SOPS Configuration](reference/sops-configuration.md)

### Explanation
- [Architecture Overview](explanation/architecture.md)
- [GitOps Workflow](explanation/gitops-workflow.md)
- [Base, Override, and Enterprise Values](explanation/three-tier-values.md)
- [Enterprise Components](explanation/enterprise-components.md)
- [Security Model](explanation/security-model.md)
