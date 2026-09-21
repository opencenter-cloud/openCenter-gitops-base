---
id: catalog-schema
title: "Catalog Schema Reference"
sidebar_label: Catalog Schema
description: Proposed schema for per-service catalog fragments, the generated aggregate, and blueprint definition files in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, architects"
tags: [catalog, schema, reference, blueprints, services]
---

# Catalog Schema Reference

**Purpose:** For platform engineers and architects, documents the proposed catalog fragment schema, the generated aggregate, and the blueprint definition format, including every field, its permitted values, and how the four nested services are modeled.

**Type:** Reference
**Audience:** Service authors, tooling authors
**Last Updated:** 2026-09-21

## Status

Proposed. No files described on this page exist yet.

## File Layout

Catalog metadata lives beside the service it describes, and an aggregate is generated for consumers.

| Path | Authored or generated | Purpose |
|------|----------------------|---------|
| `applications/base/services/<service>/catalog.yaml` | authored | One fragment per service directory |
| `applications/catalog.lock.yaml` | generated, committed | Merged aggregate — the single file consumers read |
| `applications/blueprints/<blueprint>.yaml` | authored | Blueprint membership and per-blueprint overrides |
| `applications/catalog.schema.json` | authored | JSON Schema for fragment validation in CI |

Per-service fragments rather than one large file, for two reasons: a pull request adding a service touches exactly one directory, and metadata stays adjacent to the manifests it describes. The generated aggregate exists so consumers fetch one file at a known path instead of walking 44 directories.

## ServiceEntry

```yaml
apiVersion: catalog.opencenter.dev/v1alpha1
kind: ServiceEntry
name: kserve
path: applications/base/services/kserve
packaging: ociHelm
version: v0.18.0
namespace: kserve
source:
  name: kserve
  url: oci://ghcr.io/kserve/charts
components:
  - name: kserve-crd
    kind: crds
blueprints:
  - { name: ai-ml, tier: recommended }
requires: [cert-manager]
maturity: alpha
defaultEnabled: false
```

### Fields

| Field | Type | Required | Meaning |
|-------|------|----------|---------|
| `apiVersion` | string | yes | `catalog.opencenter.dev/v1alpha1` |
| `kind` | string | yes | `ServiceEntry` |
| `name` | string | yes | Catalog key. Lowercase, digits, hyphens. Must be unique across the catalog and must match the openCenter-cli service name where one exists |
| `path` | string | yes | Repository-relative path to the service directory. **The only place this string is authored.** Must resolve to an existing directory |
| `packaging` | enum | yes | See [Packaging](#packaging) |
| `version` | string | conditional | The single source of truth for the service version. Required unless `packaging: composite`, where versions live on subcomponents |
| `namespace` | string | conditional | Target namespace. Required unless `packaging: composite` |
| `source` | object | conditional | Chart or repository source. Required for all packaging types except `olmSubscription`, `remoteKustomize`, and `composite` |
| `source.name` | string | yes within `source` | `HelmRepository`, `GitRepository`, or OCI source name as declared in `source.yaml` |
| `source.url` | string | yes within `source` | Source URL as declared in `source.yaml` |
| `components` | list | no | Additional resources shipped alongside the main release in the same directory — most commonly a split-out CRD `HelmRelease`. See [Components](#components) |
| `subcomponents` | list | conditional | Required when `packaging: composite`. See [Composite services](#composite-services) |
| `deployableAsUnit` | bool | no | Defaults `true`. Set `false` when the directory has no root `kustomization.yaml` and cannot be applied on its own |
| `blueprints` | list | no | Blueprint membership. Many-to-many; a service may appear in any number. See [Blueprint membership](#blueprint-membership) |
| `requires` | list | no | Advisory prerequisite service names, for documentation and blueprint validation. **Not** reconciliation ordering — hard FluxCD `dependsOn` ordering remains the render catalog's concern |
| `maturity` | enum | no | `stable`, `beta`, or `alpha`. Defaults `stable`. An `alpha` entry must set `defaultEnabled: false` |
| `defaultEnabled` | bool | no | Defaults `false`. Whether a blueprint that includes this service enables it without explicit opt-in |
| `renderOwner` | enum | no | `renderCatalog`, `descriptor`, or `none`. Records whether openCenter-cli can deploy the service today. `none` means present but not deployable |
| `versionWaiver` | string | no | Free-text justification. Suppresses the version-consistency gate for one entry. Requires a reason; an empty value is rejected |

### Packaging

The enum has five values because the directories genuinely differ in kind, not merely in configuration.

| Value | Shape on disk | Where the version lives |
|-------|---------------|-------------------------|
| `helmRepository` | `HelmRelease` + `source.yaml` declaring an HTTPS `HelmRepository` | `HelmRelease` `spec.chart.spec.version` |
| `ociHelm` | `HelmRelease` + `source.yaml` declaring an `oci://` source | `HelmRelease` `spec.chart.spec.version` |
| `gitRepository` | `HelmRelease` sourced from a `GitRepository` at a git tag | `GitRepository` `spec.ref.tag` |
| `olmSubscription` | `Subscription` + `OperatorGroup`, no Helm | `Subscription` `spec.channel`, and `spec.startingCSV` where pinned |
| `remoteKustomize` | `kustomization.yaml` referencing remote URLs only | Embedded in the remote URL or `?ref=` |
| `composite` | No root `kustomization.yaml`; multiple deployables under sub-paths | On each subcomponent |

`gitRepository` exists because `mlflow-operator` and `triton-inference-server` source from git tags rather than Helm repositories. `remoteKustomize` exists because `olm` and `external-snapshotter` have no `HelmRelease` at all — they apply pinned remote manifests, so a Helm-centric schema cannot describe them.

### Components

`components` describes additional resources in the *same* directory that are part of one logical service — distinct from `subcomponents`, which describes separately deployable sub-paths.

```yaml
components:
  - name: calico-crds
    kind: crds
```

| Field | Type | Meaning |
|-------|------|---------|
| `name` | string | Resource name as declared in the manifest, e.g. the CRD `HelmRelease` name |
| `kind` | enum | `crds`, `storageclass`, or `extra` |

Services with a split-out CRD `HelmRelease` — `calico`, `kserve`, `slurm-operator`, and `istio/base` — carry the service version in both HelmReleases. Declaring the component lets the version gate check both.

### Composite services

Four services have no root `kustomization.yaml` and cannot be applied from their own directory. They set `packaging: composite`, `deployableAsUnit: false`, and enumerate their children. `observability` is the fullest case:

```yaml
apiVersion: catalog.opencenter.dev/v1alpha1
kind: ServiceEntry
name: observability
path: applications/base/services/observability
packaging: composite
deployableAsUnit: false
subcomponents:
  - name: namespace
    path: namespace
    role: prerequisite
    deployable: false
  - name: sources
    path: sources
    role: prerequisite
    deployable: false
  - name: kube-prometheus-stack
    path: kube-prometheus-stack
    packaging: helmRepository
    version: 77.6.0
    namespace: observability
    deployable: true
    blueprints:
      - { name: minimal,     tier: required }
      - { name: enterprise,  tier: required }
      - { name: observability, tier: required }
  - name: loki
    path: loki
    packaging: helmRepository
    version: 6.45.2
    namespace: observability
    deployable: true
    requires: [sources]
  - name: mimir
    path: mimir
    packaging: helmRepository
    version: 6.0.3
    namespace: observability
    deployable: true
    requires: [sources]
  - name: tempo
    path: tempo
    packaging: helmRepository
    version: 1.55.0
    namespace: observability
    deployable: true
    requires: [sources]
  - name: opentelemetry-kube-stack
    path: opentelemetry-kube-stack
    packaging: helmRepository
    version: 0.11.1
    namespace: observability
    deployable: true
```

#### Subcomponent fields

| Field | Type | Required | Meaning |
|-------|------|----------|---------|
| `name` | string | yes | Subcomponent key, unique within the parent |
| `path` | string | yes | Path relative to the parent's `path` |
| `role` | enum | no | `component` (default) or `prerequisite`. A `prerequisite` supplies a shared namespace or source and is not a workload |
| `deployable` | bool | yes | Whether the sub-path has its own `kustomization.yaml` and can be applied independently |
| `packaging`, `version`, `namespace`, `source`, `requires`, `blueprints` | | conditional | Same semantics as on `ServiceEntry`. Required when `deployable: true` |

A subcomponent with `deployable: true` may be referenced by a blueprint directly, addressed as `<parent>/<name>`. This is what lets a blueprint include `observability/loki` without inventing a top-level `loki` directory.

The other three composites:

| Service | Subcomponents | Notes |
|---------|---------------|-------|
| `kyverno` | `policy-engine` (deployable), `default-ruleset` (deployable, 17 ClusterPolicy manifests, requires the engine) | `default-ruleset` is raw custom resources with no Helm values |
| `istio` | `base`, `istiod`, `gateway` (all deployable, strictly ordered), `sources` and `namespace` (prerequisites) | Version `1.28.3` repeats across all three HelmReleases plus the values filename |
| `keycloak` | `00-postgres`, `10-operator`, `20-keycloak`, `30-oidc-rbac` | Ordered by prefix. Mixed packaging: `10-operator` is `olmSubscription`, the others are custom resources |

## Blueprint Membership

Membership is declared on both sides and resolved by joining on name. The `ServiceEntry` records which blueprints claim it; the blueprint file records its members and any per-blueprint override. CI enforces that the two agree, so neither can drift silently.

```yaml
blueprints:
  - { name: enterprise, tier: required }
  - { name: ai-ml,      tier: recommended, defaultEnabled: true }
```

| Field | Type | Meaning |
|-------|------|---------|
| `name` | string | Blueprint name; must resolve to a file in `applications/blueprints/` |
| `tier` | enum | `required`, `recommended`, or `optional` |
| `defaultEnabled` | bool | Per-blueprint override of the entry's own `defaultEnabled` |

### Blueprint file

```yaml
apiVersion: catalog.opencenter.dev/v1alpha1
kind: Blueprint
name: ai-ml
title: "AI/ML Platform"
description: Model training, inference serving, experiment tracking, feature stores, vector databases, and notebook environments.
extends: enterprise
members:
  - nvidia-gpu-operator
  - amd-gpu-operator
  - node-feature-discovery
  - kueue
  - kuberay-operator
  - training-operator
  - kserve
  - triton-inference-server
  - vllm
  - mlflow-operator
  - model-registry-operator
  - data-science-pipelines-operator
  - feast-operator
  - trustyai-service-operator
  - milvus-operator
  - jupyterhub
  - slurm-operator
choices:
  - name: gpu-vendor
    description: Select per hardware fleet.
    oneOf: [nvidia-gpu-operator, amd-gpu-operator]
```

| Field | Type | Required | Meaning |
|-------|------|----------|---------|
| `name` | string | yes | Blueprint key, matching the filename stem |
| `title`, `description` | string | yes | Human-facing labels used in generated documentation |
| `extends` | string | no | Inherit another blueprint's members. Resolved transitively; cycles are rejected |
| `members` | list | yes | Service names, or `<parent>/<subcomponent>` for a composite child |
| `choices` | list | no | Mutually exclusive alternatives. `oneOf` members are exempt from "all members enabled" validation |

`choices` models the CNI selection that `reference/service-categories.md` currently expresses as a prose note ("choose one") across several categories, and the GPU vendor split in AI/ML.

## Generated Aggregate

`applications/catalog.lock.yaml` is the merge of all fragments, deterministically ordered by service name, with `extends` chains resolved and blueprint membership denormalized onto each entry. It is generated and committed so that a consumer needs exactly one fetch, and so that a diff in a pull request shows the effective change rather than only the fragment edit.

Regeneration must be byte-reproducible from the fragments. CI regenerates it and fails when the committed file differs.

## Validation

The JSON Schema covers structure. Four checks require reading the manifests and are described in the [Migration Plan](migration-plan.md#phase-2--gates-and-generated-documentation):

1. Every service directory has a fragment, and every fragment's `path` resolves.
2. `version` equals the `HelmRelease` chart version, the `helm-values/values-<version>.yaml` filename, and every declared CRD component's version.
3. Every file in `helm-values/` is referenced by some `secretGenerator`.
4. Every blueprint member resolves to a catalog entry or a deployable subcomponent, and blueprint membership agrees in both directions.

## Related

- [Service Catalog](index.md) — why the catalog exists and what it consolidates
- [Current State](current-state.md) — the taxonomy the schema was derived from
- [Migration Plan](migration-plan.md) — delivery phases
- [Helm Values Schema](../reference/helm-values-schema.md) — the values layering the catalog describes but does not change
