---
id: service-catalog
title: "Service Catalog Reference"
sidebar_label: Service Catalog
description: Navigation reference for the services available in openCenter-gitops-base and where to find the authoritative service inventory.
doc_type: reference
audience: "platform engineers, operators, architects"
tags: [services, catalog, kubernetes, platform]
---

# Service Catalog Reference

Use this page to navigate the service inventory in `openCenter-gitops-base`.

The authoritative list of services and versions is maintained in the [Available Applications](../../README.md#available-applications) section of the top-level README. That section should be treated as the source of truth for:

- service names
- namespaces
- pinned versions
- service README entry points

For deeper per-service background, use the [Service Reference Library](services/index.md).

## Service Inventory

The repository currently provides:

- core platform services under `applications/base/services/`
- observability components under `applications/base/services/observability/`
- managed services under `applications/base/managed-services/`
- policy resources under `applications/policies/`

## Recommended Navigation

Use these entry points depending on what you need:

- [Available Applications](../../README.md#available-applications) for the complete service and version tables
- [Service Reference Library](services/index.md) for service purpose, use cases, integration points, and upstream references
- [Service Configuration Guides](../how-to/services/index.md) for practical override and validation guidance
- [Directory Structure](directory-structure.md) for repository layout and service placement
- [Kustomize Patterns](kustomize-patterns.md) for the base service composition model

## Service Groupings

### Core Platform Services

Core services are defined under `applications/base/services/` and include cluster capabilities such as:

- certificate management
- ingress and traffic management
- identity and access management
- policy and governance
- storage and backup
- cloud-provider integrations
- operators and supporting platform controllers

See [Available Applications](../../README.md#available-applications) for the exact current list and versions.

### Observability Stack

Observability components are grouped under `applications/base/services/observability/` and include metrics, logging, tracing, and telemetry collection.

See:

- [README](../../README.md)
- [Available Applications](../../README.md#available-applications)
- [Service Reference Library](services/index.md)

### Managed Services

Managed services live under `applications/base/managed-services/`.

These services are maintained separately from the core platform service catalog but still follow the same repo-level documentation model:

- repo-local service README
- optional reference and how-to documentation where needed

### Policies

Policy resources under `applications/policies/` are part of the platform baseline but are not listed in the service reference library as deployable application services.

## Source Material

This page is derived from:

- [README](../../README.md)
- [applications/base/services/](../../applications/base/services/)
- [applications/base/managed-services/](../../applications/base/managed-services/)
- [applications/policies/](../../applications/policies/)
- [Service Reference Library](services/index.md)
