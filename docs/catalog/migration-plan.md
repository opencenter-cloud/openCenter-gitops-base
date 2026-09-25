---
id: catalog-migration-plan
title: "Catalog Migration Plan"
sidebar_label: Migration Plan
description: Status and remaining work for the implemented service inventory catalog, its gates, generated aggregate, and external renderer questions.
doc_type: explanation
audience: "platform engineers, architects, maintainers"
tags: [catalog, migration, plan, roadmap, blueprints]
---

# Catalog Migration Plan

**Purpose:** Separate catalog work already implemented in this repository from remaining fixes and cross-repository proposals.

## Current status

The repository contains the implementation described by the inventory-catalog phases:

- service fragments and JSON Schema exist;
- the generated lock exists;
- blueprint files exist;
- `catalog.py` implements schema, manifest, freshness, and blueprint gates;
- the pre-commit configuration invokes the catalog checks;
- catalog tooling can regenerate service-category documentation.

The repository-local catalog implementation is green at this revision: all 47 service directories have fragments, the generated lock contains 47 service entries, KEDA metadata is included, and the catalog gates pass.

## Remaining repository-local work

1. Keep versions, values filenames, components, and blueprint membership aligned as services change.
2. Regenerate and verify the lock and catalog-generated documentation when their source fragments or blueprints change.
3. Keep catalog-backed service reference, operations, and inventory documentation synchronized with those metadata changes.

These are repository-local implementation/maintenance tasks. No directory move is required for them.

## Proposed external work

The following is **not implemented in this repository**:

- making an external openCenter-cli read the catalog;
- replacing external renderer or descriptor ownership with catalog data;
- wiring entries whose `renderOwner` is `none` into an external renderer;
- changing Flux consumer paths or private enterprise overlays;
- reorganizing service directories.

The checkout contains no openCenter-cli source, private enterprise repository, rendered customer trees, or live cluster. Any such work requires its owner to define the read path, compatibility checks, ref pinning, and rollout separately.

## Validation boundary

The local `catalog.py` gates validate catalog files and selected repository manifests. They do not prove chart availability, Helm rendering, Flux reconciliation, external CLI behavior, private repository behavior, or live-cluster safety.

## Explicit non-goals

- The catalog is not a manifest generator.
- Blueprint membership does not activate a service.
- The `enterprise` blueprint does not implement a private enterprise edition.
- The `path` field does not authorize moving directories or update consumer references.

## Related

- [Service Catalog](index.md)
- [Catalog Schema](schema.md)
- [Current State](current-state.md)
