---
id: catalog-migration-plan
title: "Catalog Migration Plan"
sidebar_label: Migration Plan
description: Phased plan for introducing the service catalog, converging the openCenter-cli render catalog onto it, and the decisions that remain open.
doc_type: explanation
audience: "platform engineers, architects, maintainers"
tags: [catalog, migration, plan, roadmap, blueprints]
---

# Catalog Migration Plan

**Purpose:** For platform engineers, architects, and maintainers, explains how the service catalog is delivered in phases, what each phase must satisfy before it is considered done, which decisions are still open, and which approaches were rejected.

**Type:** Explanation
**Audience:** Maintainers
**Last Updated:** 2026-09-21

## Status

Proposed. No phase has started.

## Sequencing Principle

Phases 1 through 3 live entirely inside this repository and touch no consumer. Phase 4 is the only cross-repository work. Phase 5 is a separate decision that may never be taken.

That ordering is deliberate. The blueprint problem that motivated this work — AI/ML services accumulating in a flat tree with no way to express which profile they belong to — is fully resolved at the end of phase 3, with nothing moved and no consumer touched. Phase 4 buys a single source of truth for rendering; phase 5 buys directory browsability. Neither is a prerequisite for the value in phases 1 to 3, and both carry risk the earlier phases do not.

## Phase 1 — Inventory Catalog

Author the catalog with no consumers and no gates.

**Work.** One `catalog.yaml` fragment per service directory following [the schema](schema.md). The JSON Schema at `applications/catalog.schema.json`. The generator producing `applications/catalog.lock.yaml`. The four composite services — `observability`, `kyverno`, `istio`, `keycloak` — are the substantive part; the 32 single-HelmRelease leaves are mechanical.

**Acceptance.**

- Every directory under `applications/base/services/` has a fragment.
- Every fragment validates against the JSON Schema.
- Every fragment's `path` resolves to an existing directory.
- `catalog.lock.yaml` regenerates byte-identically from the fragments on a clean checkout.
- `check-yaml` and `yamllint` pass via the existing pre-commit hook.

**Blast radius.** None. Additive files only; no existing consumer reads them.

## Phase 2 — Gates and Generated Documentation

Make the catalog authoritative for documentation, and make its accuracy enforced rather than assumed.

**Gates to add.** Four checks beyond schema validation, each requiring the manifests to be read:

1. **Fragment coverage.** Every service directory has a fragment; every fragment's path resolves. Fails on an added service with no fragment.
2. **Version consistency.** `version` equals the `HelmRelease` chart version, equals the `helm-values/values-<version>.yaml` filename, and equals every declared CRD component's version. Waivable only through an explicit `versionWaiver` with a stated reason.
3. **Orphaned values.** Every file under `helm-values/` is referenced by some `secretGenerator`.
4. **Aggregate freshness.** `catalog.lock.yaml` matches what the generator produces from the fragments.

**Defects these gates will fail on.** All are catalogued in [Current State](current-state.md#known-drift-defects) and must be fixed or explicitly waived in this phase, not deferred: the `latest`-versus-pinned disagreements for `amd-gpu-operator`, `node-feature-discovery`, `vllm`, and `slurm-operator`; the orphaned `values-v26.3.2-mig.yaml` and `values-1.6.1.yaml`; the `keycloak/20-keycloak` placeholder hostname. Landing the gates and the fixes in the same phase avoids merging a catalog that is known-red on arrival.

**Generated documentation.** Regenerate `reference/service-categories.md` and the README service tables from the catalog, then delete the hand-maintained lists. This is the point at which 224 hand-maintained lines stop being able to disagree with the tree.

Note that `reference/service-categories.md` currently fails the frontmatter audit for missing frontmatter. Generated output must emit compliant frontmatter, which incidentally fixes that pre-existing failure.

**Acceptance.**

- All four gates run in CI and fail on a seeded violation of each.
- Every defect above is fixed or waived with a reason.
- `reference/service-categories.md` and the README tables are byte-reproducible from the catalog.
- The frontmatter audit passes on all generated pages.

**Blast radius.** Confined to this repository. Documentation consumers see regenerated content with the same information and corrected versions.

## Phase 3 — Blueprints

Give blueprint membership a home.

**Work.** `applications/blueprints/*.yaml` for the categories `reference/service-categories.md` defines today: Minimal, Enterprise, AI/ML, Observability, Storage, Networking, Security and Policy, Data and Messaging, Cloud Provider Integration, HPC and Batch, and Operator Infrastructure. `extends` chains where a blueprint genuinely builds on another. `choices` for the CNI selection and the GPU vendor split, both of which are prose notes today. A gate validating that every member resolves and that membership agrees in both directions.

Blueprint membership stays a many-to-many join on names. `defaultEnabled` and `maturity` carry the "not all services will be deployed" requirement: a blueprint can include a service without enabling it, and an `alpha` service is never on by default.

**Acceptance.**

- Every blueprint member resolves to a catalog entry or a deployable subcomponent.
- Membership declared on a `ServiceEntry` and on a `Blueprint` agree; a one-sided declaration fails CI.
- The AI/ML blueprint reproduces the 17-service list currently in `reference/service-categories.md`.
- `extends` cycles are rejected.
- Generated documentation renders blueprints from these files rather than from hand-written tables.

**Blast radius.** None outside this repository.

At the end of this phase the original problem is solved: a new blueprint is a new file, AI/ML services are grouped without duplication, services shared across blueprints are declared once, and undeployable services are visible as such.

## Phase 4 — openCenter-cli Convergence

Collapse the render catalog onto the inventory catalog. This is the only cross-repository phase.

**Prerequisite, not optional.** Regenerate the `testdata/relaypoint-logistics-shared` golden fixture from a known-good build first. It does not exist on disk today, so `relaypoint_parity_test.go` skips and there is no byte-level safety net for a renderer refactor. Beginning phase 4 without it means changing rendering with only two hardcoded unit assertions as cover.

**Work.**

- Add the catalog reader per the [read-path decision](#open-decisions).
- Migrate the 19 data fields of all 22 `RenderSpec` entries so `BasePath` is no longer a Go literal.
- Move the 8 `templateRenderer` literals and `staticRenderer(otelTemplate)` to template files.
- Leave `veleroRenderer` and `metallbOverlayFilesRenderer` as registry-keyed code hooks — they are genuine Go control flow, not templates. The catalog declares `renderer: velero`; the code still supplies the behavior.
- Export the template binding contract: the templates bind against the whole `v2.Config` plus the custom `objectStorageBackend` function.
- Extend `ValidateConfigOwnership` to recognize a third ownership source without weakening the disjointness rule.

**Acceptance.**

- No `applications/base/services/...` string literal remains in `render_catalog.go`.
- Rendering every fixture cluster configuration produces byte-identical output to the pre-change build.
- A service present in the catalog but with no render owner produces a clear diagnostic, not a hard failure with an opaque message.

**Blast radius.** openCenter-cli only, provided output stays byte-identical. Rendered cluster trees are unchanged.

### Related but separately scoped

Roughly 14 services — substantially the AI/ML set — have no render owner and therefore cannot be deployed at all today. Cataloguing them in phase 1 makes that visible; it does not make them deployable. Wiring them is per-service work in openCenter-cli and should be scoped explicitly, because it is the difference between the AI blueprint being *documented* and being *deployable*. It can run in parallel with phases 1 to 3 and does not depend on phase 4.

## Phase 5 — Directory Reorganization

Optional, and a separate decision. Only consider it after `path` is a catalog field.

The blast radius is measured in [Current State](current-state.md#coupling-and-blast-radius). The decisive fact: rendered customer clusters carry the path in a Flux `Kustomization` `spec.path`, pinning is not uniform across clusters, and branch-tracking production clusters in a second GitHub organization would break on the commit that lands the move. Compile-time and build-time consumers fail loudly in CI; that one fails on a cluster.

It is worth asking at that point whether the move is still wanted. The motivation was browsability, and a generated inventory plus blueprint files already provides it without spending this risk.

## Open Decisions

### Read path for openCenter-cli

Does not gate phases 1 to 3 — the inventory catalog is identical under all three.

| Option | Mechanism | Trade-off |
|--------|-----------|-----------|
| **Generated Go, drift-gated** *(recommended)* | A generator turns `catalog.lock.yaml` into a Go source file committed to openCenter-cli; CI fails when it diverges from the pinned base ref | Keeps the CLI hermetic and offline, which the air-gap work depends on. Divergence is a red build, not a broken reconcile. Cost: a real sync step, and the CLI may lag the base repository between regenerations |
| **Runtime fetch** | The CLI reads the catalog from the same base repository and ref it writes into `GitRepository` sources | Purest single source of truth. Cost: introduces a network dependency and a new class of render failure the CLI does not have today; complicates air-gapped operation |
| **Keep render specs in the CLI** | Extend the existing embedded YAML descriptor pattern to absorb the 22 Go entries; this repository's catalog serves documentation, blueprints, and gates only | Cheapest, and decouples the two release cycles. Cost: `path` still lives in two repositories, so the drift is reduced rather than eliminated |

### Scope of the deployability gap

Whether wiring the ~14 unowned services into openCenter-cli is part of this effort or a follow-on. It is the item with the most direct user-visible value and the least dependency on the rest of the plan.

### Placement of this documentation

`docs/catalog/` sits outside the repository's lifecycle-based documentation layout (`getting-started/`, `operations/`, `reference/`, `concepts/`, `release/`, `contributing/`). A conforming alternative would split these pages across `concepts/` for the rationale, `reference/` for the schema and baseline, and `operations/` for the authoring procedure. Kept together here for now because the set is a single proposal under active discussion.

## Rejected Approaches

**Generating manifests from the catalog.** FluxCD reconciles the manifests directly, so a generator in that path converts a catalog defect into a cluster outage. The catalog stays descriptive, and CI enforces that the description matches what is on disk.

**Encoding blueprint membership in the directory tree.** A service belongs to several blueprints; a directory can hold it once. The result is either duplicated definitions or a `shared/` directory that recreates today's flat tree with an added judgment call per service. A join on names is many-to-many at no cost.

**A single large catalog file.** 44 entries in one file is a merge-conflict magnet and separates metadata from the manifests it describes. Per-service fragments keep a service's pull request inside one directory; the generated aggregate gives consumers the single-file read they want.

**Claiming the render catalog becomes pure YAML.** Two fields hold genuine Go control flow — `veleroRenderer` branches on provider and storage type with hardcoded plugin image tags, and `metallbOverlayFilesRenderer` is bespoke. A plan promising full YAML expression would fail in phase 4 on those two.

**Moving directories in the same change as introducing the catalog.** The move's value depends on the catalog existing first, and combining them means the risky half cannot be reverted without losing the safe half.

## Related

- [Service Catalog](index.md) — the problem and the two-catalog split
- [Catalog Schema](schema.md) — the schema each phase authors against
- [Current State](current-state.md) — the measured baseline and defect list
