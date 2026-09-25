---
id: enterprise-components
sidebar_label: Enterprise Components
description: Boundary between the public base manifests and private or consumer-owned enterprise composition.
doc_type: explanation
title: "Enterprise Components Pattern"
audience: "platform engineers, architects"
tags: [enterprise, kustomize, architecture, overlays]
---

# Enterprise Components Pattern

## What is implemented here

The base service manifests and catalog entries in this repository use the public sources recorded in their `source.yaml` files and `catalog.yaml` fragments. The `enterprise` blueprint is an implemented catalog grouping, not a private overlay implementation.

There is no `applications/enterprise/` tree or private enterprise repository checkout here. Consequently, this repository cannot establish the exact structure, patch targets, source rewrites, image rewrites, or authentication behavior of a private enterprise layer.

## Private/consumer responsibility

A consuming private repository may compose base paths with its own Kustomize resources, but that is external behavior. The private or cluster repository must own and verify:

- which base ref and service path it imports;
- source and image changes;
- private registry credentials;
- enterprise-only values, patches, and custom resources;
- the Flux path and dependencies used by a target cluster.

Those changes should not be inferred from the public base catalog or from the name of the `enterprise` blueprint.

## What the base exports

The base exports reusable service directories such as `applications/base/services/cert-manager` and composite child paths such as `applications/base/services/observability/loki`. It also exports the catalog lock for inventory consumers. A consumer chooses and activates these paths; the base does not activate them into a cluster.

## Status labels

- **Implemented:** public base manifests, public source declarations, catalog metadata, and blueprint membership in this repository.
- **External responsibility:** private overlay composition, private sources/images, credentials, and cluster activation.
- **Not evidenced:** a particular enterprise repository layout or a guarantee that any private overlay currently consumes a given base ref.

## Related

- [Architecture Explanation](architecture.md)
- [Base, Override, and Enterprise Values](three-tier-values.md)
- [Service Catalog](../catalog/index.md)
