---
id: catalog-index
title: "Service Catalog"
sidebar_label: Service Catalog
description: Why openCenter-gitops-base needs a declarative service catalog, what it replaces, and how the catalog documentation set is organized.
doc_type: explanation
audience: "platform engineers, operators, architects"
tags: [catalog, services, blueprints, inventory, architecture]
---

# Service Catalog

**Purpose:** For platform engineers, operators, and architects, explains why this repository needs a declarative service catalog, which existing representations it consolidates, and where to find the schema, the current-state evidence, and the migration plan.

**Type:** Explanation
**Audience:** All users
**Last Updated:** 2026-09-21

## Status

Proposed. Nothing in this documentation set is implemented yet. No `catalog.yaml` exists in this repository, and no consumer reads one.

## The Problem

The set of services this repository provides is currently expressed four separate times, in two repositories, with no cross-checks between any pair.

| Representation | Location | Coverage | Owner |
|----------------|----------|----------|-------|
| Directory tree | `applications/base/services/*/` | 44 services | this repository |
| Go `RenderSpec` structs | `openCenter-cli` `internal/gitops/render_catalog.go` | 22 services | openCenter-cli |
| Embedded YAML descriptors | `openCenter-cli` `internal/services/descriptors/data/` | ~8 services | openCenter-cli |
| Hand-written Markdown | [`reference/service-categories.md`](../reference/service-categories.md) | 44 names in 13 categories | this repository |

Because nothing reconciles them, they have already diverged. The Markdown inventory lists `amd-gpu-operator`, `node-feature-discovery`, `vllm`, and `slurm-operator` as version `latest` while all four pin concrete chart versions on disk. See [Current State](current-state.md) for the full defect list.

Two further problems follow from the same root cause.

**Blueprint membership has no home.** openCenter operates a blueprint model — Minimal, Enterprise, AI/ML, Observability, and others — but a service belongs to several blueprints at once. `postgres-operator` is in Enterprise and AI/ML, `nvidia-gpu-operator` is in AI/ML and HPC, and the observability stack appears in nearly every profile. Blueprint membership is therefore a many-to-many relation, and a directory tree can only express one-to-many. Encoding blueprints as directories forces either duplicated service definitions or a `shared/` escape hatch that reproduces today's flat tree with extra indirection.

**Deployability is invisible.** Of the 44 service directories present, roughly 30 have a rendering owner in openCenter-cli; the remaining ~14 — nearly the entire AI/ML set — cannot be enabled at all, because the CLI hard-errors on an enabled service that has neither a descriptor nor a render-catalog entry. That a service exists in this repository is currently no indication that it can be deployed.

## Two Catalogs, Not One

The word "catalog" covers two distinct concerns with different natural owners and very different risk profiles. Separating them is what makes this work incremental.

| | Inventory catalog | Render catalog |
|---|---|---|
| Answers | Which services exist, how they are packaged, at what version, in which blueprints, enabled by default | How openCenter-cli wires a service into FluxCD |
| Natural owner | this repository — it describes its own tree | openCenter-cli — it describes its own rendering |
| Coverage | all 44 directories | 22 of 44 |
| Fields | ~10, all plain data | ~21, two of them Go functions |
| Cross-repository risk | none | high |
| Resolves blueprint membership | yes | no |

The inventory catalog is additive, has no existing consumers to break, and is sufficient on its own to give blueprints a home and to stop the version drift. The render catalog convergence is a separate, optional project in another repository that only becomes worthwhile once an inventory exists to converge onto.

## Design Constraints

Three constraints are non-negotiable and shape the schema.

**The catalog is descriptive, never generative.** It does not generate `HelmRelease` or `Kustomization` manifests. FluxCD reconciles the manifests directly, so a generator in that path would turn a catalog defect into a cluster outage. The catalog describes what is on disk, and CI enforces that the description matches.

**No service directory moves.** The service path becomes a catalog *field*, which is what makes any future reorganization cheap. Moving directories now would break consumers at three different lifecycle stages, one of which fails on a live cluster rather than in CI. See [Current State](current-state.md#coupling-and-blast-radius).

**Directory names are not usable as keys.** Four services — `observability`, `kyverno`, `istio`, and `keycloak` — have no root `kustomization.yaml` and cannot be applied from their own directory; they contain 7, 2, 5, and 4 sub-paths respectively. Separately, `reference/service-categories.md` names `loki`, `mimir`, `tempo`, `kube-prometheus-stack`, and `opentelemetry-kube-stack` as top-level services when all five exist only as children of `observability/`. The catalog must therefore be keyed on declared service names with an explicit subcomponent list.

## Documentation Set

| Page | What it covers |
|------|----------------|
| [Catalog Schema](schema.md) | The `ServiceEntry` schema, the packaging enum, subcomponents, blueprint files, and the generated aggregate |
| [Current State](current-state.md) | Evidence: the 44-directory taxonomy, the openCenter-cli catalog's data-versus-code split, the coverage gap, known drift defects, and the consumer blast radius |
| [Migration Plan](migration-plan.md) | Phased delivery with acceptance criteria, and the decisions still open |

## Related

- [Directory Structure](../reference/directory-structure.md) — current repository layout
- [Service Categories](../reference/service-categories.md) — the hand-maintained inventory this work replaces with generated output
- [Enterprise Components Pattern](../concepts/enterprise-components.md) — how the private enterprise repository composes on top of this base
- [Add a Helm Service to the Community Repo](../operations/add-helm-service-to-community-repo.md) — the onboarding path that gains a catalog fragment step
