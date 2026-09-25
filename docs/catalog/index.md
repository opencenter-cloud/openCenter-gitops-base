---
id: catalog-index
title: "Service Catalog"
sidebar_label: Service Catalog
description: Implemented service inventory catalog, its generated aggregate, validation boundaries, and external renderer questions.
doc_type: explanation
audience: "platform engineers, operators, architects"
tags: [catalog, services, blueprints, inventory, architecture]
---

# Service Catalog

**Purpose:** Explain the catalog artifacts currently implemented in this repository and distinguish them from proposed cross-repository work.

## Status

The inventory catalog is **implemented**:

- per-service fragments exist for all 47 service directories;
- `applications/catalog.schema.json` defines the fragment schema;
- `applications/catalog.lock.yaml` is a generated, committed aggregate;
- 11 blueprint files exist under `applications/blueprints/`;
- `hack/scripts/catalog.py` validates fragments, checks gates, regenerates the lock, and can regenerate service-category documentation;
- the pre-commit configuration invokes `catalog.py all` for catalog changes.

The current repository has 47 directories under `applications/base/services/`, and all 47 have catalog fragments. The coverage gate passes, including for `keda`.

## What the catalog describes

The catalog is descriptive. A fragment records a service path, packaging type, version where applicable, namespace/source metadata, components or subcomponents, blueprint membership, prerequisites, maturity, default-enabled metadata, and a declared `renderOwner`. The catalog tool does not generate HelmRelease or Kustomization manifests.

The lock contains 47 service entries and 11 blueprint entries. Composite entries model separately deployable children without moving service directories. The implemented composite entries are `ceph-csi`, `observability`, `kyverno`, `istio`, and `keycloak`.

## Ownership boundaries

The catalog files are owned by this repository. A consumer may read the committed lock, but no reader for an external CLI is present in this checkout. `renderOwner` is catalog metadata; it is not evidence that an external renderer is implemented or that a live cluster can deploy the entry.

Blueprint membership is repository metadata. Cluster activation, Flux ordering, secrets, override values, and private-repository composition remain consumer responsibilities.

## Proposed or not evidenced

- No cross-repository reader or render-catalog convergence is implemented here.
- Directory reorganization is not implemented and should not be inferred from the catalog's `path` field.
- Catalog coverage is complete for the service directories at the current revision.

## Documentation set

| Page | Scope |
| --- | --- |
| [Catalog Schema](schema.md) | Implemented schema and generated-file contract |
| [Current State](current-state.md) | Counts and repository evidence at this revision |
| [Migration Plan](migration-plan.md) | Implemented phases, remaining work, and explicitly proposed external work |

## Related

- [Directory Structure](../reference/directory-structure.md)
- [Service Categories](../reference/service-categories.md)
- [Enterprise Components Pattern](../concepts/enterprise-components.md)
