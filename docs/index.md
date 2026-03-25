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

The authoritative service and version inventory is maintained in the top-level [README](../README.md). For deeper per-service documentation, use the [Service Catalog](reference/service-catalog.md) and the [Service Reference Library](reference/services/index.md).

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

**Start here:**
- [Infrastructure as Code](../iac/README.md)
- [Getting Started Tutorial](tutorials/getting-started.md)

Use the IaC guide to build a cluster, then follow the tutorial to deploy your first service (cert-manager) and understand the GitOps workflow.

### Platform Engineers

**Common tasks:**
- [Add a New Service](how-to/add-new-service.md) - Deploy additional platform services
- [Configure Helm Values](how-to/configure-helm-values.md) - Customize service configuration
- [Manage Secrets with SOPS](how-to/manage-secrets.md) - Encrypt sensitive data
- [Troubleshoot Flux](how-to/troubleshoot-flux.md) - Debug reconciliation issues
- [Configure Gateway API](how-to/configure-gateway.md) - Set up ingress routing
- [Setup Observability](how-to/setup-observability.md) - Deploy monitoring stack

**Reference documentation:**
- [iac/ README](../iac/README.md) - Cluster provisioning, Kubespray inventory generation, and bootstrap flow
- [Service Catalog](reference/service-catalog.md) - All available services
- [Directory Structure](reference/directory-structure.md) - Repository layout
- [Flux Resources](reference/flux-resources.md) - GitRepository, HelmRelease, Kustomization specs
- [Helm Values Schema](reference/helm-values-schema.md) - Base values, override values, and merge behavior
- [Kustomize Patterns](reference/kustomize-patterns.md) - Base service composition patterns
- [SOPS Configuration](reference/sops-configuration.md) - Secret encryption

### Architects and Decision Makers

**Understand the system:**
- [Architecture Overview](explanation/architecture.md) - System design and decisions
- [GitOps Workflow](explanation/gitops-workflow.md) - How FluxCD manages deployments
- [Base, Override, and Enterprise Values](explanation/three-tier-values.md) - Configuration layering rationale
- [Enterprise Components](explanation/enterprise-components.md) - How the private enterprise repo composes on top of base
- [Security Model](explanation/security-model.md) - Security controls and gaps

## Documentation Structure

This documentation follows the [Diátaxis framework](https://diataxis.fr/) with four distinct types:

### Tutorials (Learning-Oriented)

**Goal:** Build confidence through guided, end-to-end walkthroughs

- [Getting Started](tutorials/getting-started.md) - Deploy your first service

**When to use:** You're new to openCenter and want to learn by doing.

### How-To Guides (Task-Oriented)

**Goal:** Complete specific tasks with minimal background

- [Add a New Service](how-to/add-new-service.md)
- [Configure Helm Values](how-to/configure-helm-values.md)
- [Manage Secrets with SOPS](how-to/manage-secrets.md)
- [Configure Gateway API](how-to/configure-gateway.md)
- [Setup Observability](how-to/setup-observability.md)
- [Troubleshoot Flux](how-to/troubleshoot-flux.md)

**When to use:** You know what you want to do and need step-by-step instructions.

### Reference (Information-Oriented)

**Goal:** Provide exact facts for lookup

- [Directory Structure](reference/directory-structure.md)
- [Service Catalog](reference/service-catalog.md)
- [Service References](reference/services/index.md)
- [Flux Resources](reference/flux-resources.md)
- [Helm Values Schema](reference/helm-values-schema.md)
- [Kustomize Patterns](reference/kustomize-patterns.md)
- [SOPS Configuration](reference/sops-configuration.md)

**When to use:** You need to look up specifications, syntax, or available options.

### Explanation (Understanding-Oriented)

**Goal:** Build mental models and understand "why"

- [Architecture Overview](explanation/architecture.md)
- [GitOps Workflow](explanation/gitops-workflow.md)
- [Base, Override, and Enterprise Values](explanation/three-tier-values.md)
- [Enterprise Components](explanation/enterprise-components.md)
- [Security Model](explanation/security-model.md)

**When to use:** You want to understand concepts, trade-offs, and design decisions.

## Service-Specific Documentation

Each deployable service now has a dedicated reference page in the service library:

- [Service Reference Library](reference/services/index.md)

Detailed configuration guides also exist for selected services:

- [Service Configuration Guides](how-to/services/index.md)
- [cert-manager](how-to/services/cert-manager.md)
- [Harbor](how-to/services/harbor.md)
- [Keycloak](how-to/services/keycloak.md)
- [Kyverno](how-to/services/kyverno.md)
- [Longhorn](how-to/services/longhorn.md)
- [MetalLB](how-to/services/metallb.md)
- [Velero](how-to/services/velero.md)
- [vSphere CSI](how-to/services/vsphere-csi.md)
- [kube-prometheus-stack](how-to/services/kube-prometheus-stack.md)
- [Loki](how-to/services/loki.md)
- [Tempo](how-to/services/tempo.md)
- [OpenTelemetry](how-to/services/opentelemetry-kube-stack.md)
- [Sealed Secrets](how-to/services/sealed-secrets.md)
- [Adding New Service](how-to/add-new-service.md)
- [Service Standards](service-standards-and-lifecycle.md)

## Common Workflows

### Deploying a New Cluster

1. Use openCenter-cli to generate the cluster repository
2. Bootstrap FluxCD on the cluster
3. Configure GitRepository sources pointing to this repository
4. Create Kustomizations for desired services
5. Commit and push - FluxCD deploys automatically

See [Getting Started Tutorial](tutorials/getting-started.md) for detailed walkthrough.

### Adding a Service to Existing Cluster

1. Review [Service Catalog](reference/service-catalog.md) for available services
2. Create GitRepository source for the service
3. Create Kustomization pointing to service path
4. (Optional) Add cluster-specific overrides
5. Commit and push

See [Add a New Service](how-to/add-new-service.md) for step-by-step instructions.

### Customizing Service Configuration

1. Review service's base Helm values in `helm-values/` directory
2. Create override values Secret in your cluster overlay
3. Reference override Secret in HelmRelease valuesFrom
4. Commit and push

See [Configure Helm Values](how-to/configure-helm-values.md) for details.

### Troubleshooting Deployment Issues

1. Check Flux resource status: `flux get all`
2. Review Flux logs: `flux logs --level=error`
3. Describe failing resource: `kubectl describe <resource>`
4. Force reconciliation: `flux reconcile <resource>`

See [Troubleshoot Flux](how-to/troubleshoot-flux.md) for comprehensive guide.

## Getting Help

### Documentation Issues

If you find errors or gaps in documentation:
1. Review the relevant service or workflow guide in this documentation set
2. Cross-check the corresponding manifests under `applications/` or Terraform under `iac/`
3. Consult service-specific configuration guides

### Technical Support

For technical issues:
1. Review [Troubleshooting Guide](how-to/troubleshoot-flux.md)
2. Check Flux logs and resource status
3. Consult service-specific documentation
4. Review [Architecture Overview](explanation/architecture.md) for system design

### Contributing

To contribute to this repository:
1. Review [Service Standards](service-standards-and-lifecycle.md)
2. Follow [Adding New Service](how-to/add-new-service.md)
3. Use [Service Templates](templates/) for consistency
4. Ensure all changes follow GitOps principles

## Repository Information

**Repository:** [opencenter-cloud/openCenter-gitops-base](https://github.com/opencenter-cloud/openCenter-gitops-base)  
**FluxCD Version:** v2.7.0+  
**Kubernetes Version:** v1.28+  
**License:** See repository LICENSE file

**Key directories:**
- `applications/base/services/` - Core platform services
- `applications/base/services/observability/` - Monitoring, logging, tracing
- `applications/policies/` - Security and network policies
- `iac/` - Infrastructure provisioning plus Kubespray inventory generation and cluster bootstrap
- `docs/` - Documentation (you are here)

## Next Steps

**If you're new:** Start with the [Getting Started Tutorial](tutorials/getting-started.md)

**If you're deploying services:** Browse the [Service Catalog](reference/service-catalog.md)

**If you're customizing:** Read [Configure Helm Values](how-to/configure-helm-values.md)

**If you're troubleshooting:** Check [Troubleshoot Flux](how-to/troubleshoot-flux.md)

**If you want to understand the system:** Read [Architecture Overview](explanation/architecture.md)

## Source Material

This documentation is maintained from the live repository structure and manifests, including:
- [README.md](../README.md)
- [applications/base/services/](../applications/base/services/)
- [applications/policies/](../applications/policies/)
- [iac/](../iac/)
- [docs/explanation/architecture.md](explanation/architecture.md)
