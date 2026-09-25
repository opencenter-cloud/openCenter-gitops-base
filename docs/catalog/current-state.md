---
id: catalog-current-state
title: "Catalog Current State"
sidebar_label: Current State
description: Current repository evidence for service directories, catalog artifacts, packaging metadata, blueprints, and validation coverage.
doc_type: reference
audience: "platform engineers, architects"
tags: [catalog, services, reference, audit, drift]
---

# Catalog Current State

**Purpose:** Record the catalog state visible in this checkout. Counts are revision-specific and should be rechecked after service changes.

## Repository counts

At the current revision:

| Item | Count | Evidence |
| --- | ---: | --- |
| Service directories | 47 | `applications/base/services/` |
| Service fragments | 46 | `*/catalog.yaml` |
| Services in generated lock | 46 | `applications/catalog.lock.yaml` |
| Blueprint files | 11 | `applications/blueprints/*.yaml` |
| Missing fragment | 1 | `keda` |

The missing `keda/catalog.yaml` means the catalog coverage gate is not green for the current tree. The lock is therefore an aggregate of the catalogued 46 services, not a complete inventory of all 47 directories.

## Packaging recorded in the lock

The 46 lock entries are classified as:

| Packaging | Count |
| --- | ---: |
| `helmRepository` | 25 |
| `ociHelm` | 7 |
| `gitRepository` | 3 |
| `olmSubscription` | 4 |
| `remoteKustomize` | 2 |
| `composite` | 5 |

The composite parents are `ceph-csi`, `observability`, `kyverno`, `istio`, and `keycloak`. Their child paths, deployability flags, and prerequisites are recorded in the fragments and lock. They are not equivalent to a single root install path.

## Declared renderer metadata

The lock records `renderOwner` as:

| Value | Count |
| --- | ---: |
| `renderCatalog` | 22 |
| `descriptor` | 5 |
| `none` | 19 |

These are catalog declarations. The external renderer and descriptor implementations are not present in this repository, so these values must not be read as a verified live deployability result.

## Implemented tooling

`hack/scripts/catalog.py` provides schema validation, aggregate generation/checking, coverage, version, orphaned-values, aggregate-freshness, and blueprint gates. The local pre-commit configuration invokes `catalog.py all` when catalog files change. The tool also generates `docs/reference/service-categories.md`; that output is outside this documentation scope and is not edited by this page.

The catalog gates inspect manifest and values filenames. They do not render Helm charts, contact a chart registry, reconcile a cluster, or validate a private consumer repository.

## Repository evidence versus external claims

The checkout does not include openCenter-cli, a private enterprise repository, rendered customer trees, or a live cluster. Claims about external renderer ownership, private overlays, Flux runtime state, and consumer-specific path compatibility require those repositories or runtime checks.

## Related

- [Service Catalog](index.md)
- [Catalog Schema](schema.md)
- [Migration Plan](migration-plan.md)
