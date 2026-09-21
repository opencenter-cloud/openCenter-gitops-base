---
id: catalog-current-state
title: "Catalog Current State"
sidebar_label: Current State
description: Evidence baseline for the service catalog work - service taxonomy, openCenter-cli render catalog structure, deployability coverage gap, known drift defects, and consumer blast radius.
doc_type: reference
audience: "platform engineers, architects"
tags: [catalog, services, reference, audit, drift]
---

# Catalog Current State

**Purpose:** For platform engineers and architects, records the measured baseline the catalog design rests on — the packaging taxonomy of all 44 service directories, the structure of the openCenter-cli render catalog, which services can actually be deployed, the drift defects present today, and what consumes the service path.

**Type:** Reference
**Audience:** Service authors, tooling authors
**Last Updated:** 2026-09-21

## Scope

Findings were gathered on 2026-09-21 from this repository and from `openCenter-cli`, `opencenter-gitops-enterprise`, `opencenter-services-templates`, and the rendered customer trees. Counts are point-in-time; re-verify before acting on any specific number.

## Packaging Taxonomy

44 directories under `applications/base/services/`.

| Packaging | Count | Services |
|-----------|-------|----------|
| Helm, single `HelmRelease` | 32 | The common case |
| Helm with split CRD `HelmRelease` | 3 | `calico`, `kserve`, `slurm-operator` (plus `istio/base` within a composite) |
| OLM `Subscription` | 4 | `data-science-pipelines-operator`, `model-registry-operator`, `trustyai-service-operator`, `feast-operator` |
| Composite, no root `kustomization.yaml` | 4 | `observability`, `kyverno`, `istio`, `keycloak` |
| Remote kustomize only | 2 | `olm`, `external-snapshotter` |

All four OLM services target namespace `opendatahub` and draw from catalog source `operatorhubio-catalog` in namespace `olm`, making the `olm` service a hard prerequisite for the entire Open Data Hub operator set.

### Composite service contents

| Service | Sub-paths | Independently deployable | Prerequisite only |
|---------|-----------|--------------------------|-------------------|
| `observability` | 7 | `kube-prometheus-stack`, `loki`, `mimir`, `tempo`, `opentelemetry-kube-stack` | `namespace`, `sources` |
| `kyverno` | 2 | `policy-engine`, `default-ruleset` | — |
| `istio` | 5 | `base`, `istiod`, `gateway` (strictly ordered) | `namespace`, `sources` |
| `keycloak` | 4 | `00-postgres`, `10-operator` | `20-keycloak`, `30-oidc-rbac` depend on both |

None of the four can be applied from its own directory. `loki`, `mimir`, and `tempo` share `observability/sources/grafana.yaml`; the three `istio` components share `istio/sources/istio.yaml`.

### Shared sources

| Source | Consumers |
|--------|-----------|
| `grafana` | `loki`, `mimir`, `tempo` |
| `cpo` | `openstack-ccm`, `openstack-csi` |
| `istio` | `istio/base`, `istio/istiod`, `istio/gateway` |
| `operatorhubio-catalog` | all 4 OLM services plus `keycloak/10-operator` |

Seven services use OCI Helm sources. Two — `mlflow-operator` and `triton-inference-server` — source from a `GitRepository` at a git tag rather than a Helm repository.

## openCenter-cli Render Catalog

`internal/gitops/render_catalog.go` holds 22 `RenderSpec` entries. The type has roughly 21 fields; 19 are plain data and 2 hold Go functions.

### Data fields

`ServiceName`, `DefaultNamespace`, `SourceName`, `SourceGroup`, `EmitSource`, `BasePath`, `PostBaseStages`, `SingleStage`, `BaseOnly`, `OmitTargetNamespace`, `PrivilegedNamespace`, `HasOverrideValues`, `NamespaceStage`, `KustomizationName`, `EnterpriseRegistry`, `GeneratedResourceFiles`, `ExtraDependencies`, `ConditionalDependencies`, `OverrideDependsOn`, plus the static string fields `OverrideValues` and `KustomizationContent`. All are directly expressible in YAML.

### Function-valued fields

| Field | Producer | Entries | Expressible as data |
|-------|----------|---------|---------------------|
| `OverrideValuesRenderer` | `templateRenderer(<const>)` | `headlamp`, `kube-prometheus-stack`, `loki`, `mimir`, `tempo`, `openstack-ccm`, `openstack-csi`, `vsphere-csi` | Yes — the literal is a Go `text/template` string that can move to a file |
| `OverrideValuesRenderer` | `staticRenderer(otelTemplate)` | `opentelemetry-kube-stack` | Yes — no template variables; already data |
| `OverrideValuesRenderer` | `veleroRenderer` | `velero` | **No** — provider and storage-type branching, hardcoded plugin image tags, computed bucket defaults |
| `OverlayFilesRenderer` | template-based | `gateway`, `kube-prometheus-stack`, `longhorn` | Yes |
| `OverlayFilesRenderer` | `metallbOverlayFilesRenderer` | `metallb` | **No** — bespoke Go |

Consequence for the design: a catalog cannot make these fields pure data. The viable target is a renderer *key* resolved against a Go registry — the catalog declares which renderer, code still supplies how. Note also that the templates bind against the whole `v2.Config` plus a custom `objectStorageBackend` function, so relocating the literals means exporting that binding contract as well.

### Service name ownership

Two ownership sets, enforced disjoint:

- **Descriptors** — `internal/services/descriptors/data/*.yaml`, loaded via `go:embed`. Approximately 8 services including `cert-manager`, `keycloak`, `harbor`, `olm`, `kafka-cluster`, `calico`, `alert-proxy`, `etcd-backup`.
- **Render catalog** — the 22 Go entries.

`ValidateAgainstDescriptors` rejects a name owned by both. `ValidateConfigOwnership` requires every enabled, non-external service to be owned by one. A service in neither is a hard render error.

Selection comes from config: `OpenCenterConfig.Services` is a map whose values embed `services.BaseConfig`, carrying `Enabled bool` and `AdoptionMode`. A service renders when it is enabled and its adoption mode is not `external`. The config JSON Schema sets `additionalProperties: true`, so it does not constrain the legal service set — the two ownership sets do.

### The CLI does not read this repository

`//go:embed all:gitops-base-dir` embeds an *empty scaffold* — a README, `.gitignore`, and `.gitkeep` placeholders. No base manifests are vendored, cloned, or fetched at build or render time. The base repository reaches clusters only as a `GitRepository` URL and ref that the CLI writes into generated sources; FluxCD performs the pull.

This matters for the catalog read path: a catalog in this repository has no reader today, and having the CLI read one at render time would introduce a network dependency the render path does not currently have.

## Deployability Coverage Gap

44 directories; roughly 30 have a rendering owner. The unowned remainder cannot be enabled, because an enabled service with no owner is a hard error.

| Status | Approximate count | Notes |
|--------|-------------------|-------|
| Render-catalog owned | 22 | Deployable |
| Descriptor owned | ~8 | Deployable |
| No owner | ~14 | Present on disk, not deployable |

The unowned set is substantially the AI/ML inventory: `kserve`, `vllm`, `jupyterhub`, `milvus-operator`, `training-operator`, `kuberay-operator`, `kueue`, `nvidia-gpu-operator`, `amd-gpu-operator`, `triton-inference-server`, `feast-operator`, `mlflow-operator`, `model-registry-operator`, `trustyai-service-operator`, `slurm-operator`, `node-feature-discovery`.

Cataloguing these makes the gap legible. It does not close it — each still needs a render-catalog or descriptor entry in openCenter-cli before it can be deployed.

## Known Drift Defects

Present as of 2026-09-21. The version-consistency gate described in the [Migration Plan](migration-plan.md) fails on all of these.

### Version written in more than one place

| Service | Places | Value |
|---------|--------|-------|
| `calico` | `helmrelease.yaml`, `helmrelease-crds.yaml`, values filename | `v3.32.0` |
| `kserve` | `helmrelease.yaml`, `helmrelease-crd.yaml`, values filename | `v0.18.0` |
| `slurm-operator` | `helmrelease.yaml`, `helmrelease-crds.yaml`, values filename | `v1.1.1` |
| `istio` | three HelmReleases plus `base/helm-values/values-1.28.3.yaml` | `1.28.3` |

Every Helm service has at least two — the chart version and the values filename must be kept in step by hand.

### Documentation disagrees with disk

`reference/service-categories.md` records `latest` where a concrete version is pinned:

| Service | On disk | In the document |
|---------|---------|-----------------|
| `amd-gpu-operator` | `v1.5.0` | `latest` |
| `node-feature-discovery` | `0.18.3` | `latest` |
| `vllm` | `0.1.11` | `latest` |
| `slurm-operator` | `v1.1.1` | `latest` |

### Orphaned and placeholder content

| Service | Issue |
|---------|-------|
| `nvidia-gpu-operator` | `helm-values/values-v26.3.2-mig.yaml` is present but referenced by no `secretGenerator` |
| `kuberay-operator` | `helm-values/values-1.6.1.yaml` is present while the chart pins `1.4.2` |
| `keycloak/20-keycloak` | Keycloak custom resource carries the literal placeholder `hostname: https://auth.example.com # TODO: FQDN` |
| `vsphere-csi` | `crds/` entries are all commented out in `kustomization.yaml` |

### Structural inconsistencies

| Service | Deviation from siblings |
|---------|-------------------------|
| `harbor` | Namespace in a `namespace/` sub-directory rather than a flat `namespace.yaml`; `secretGenerator` omits an explicit namespace and relies on the kustomization-level setting |
| `olm` | Only `kustomization.yaml` and a README — no namespace, source, or HelmRelease |
| `external-snapshotter` | No source and no HelmRelease; applies two remote kustomize bases pinned at `?ref=v8.2.1` |
| `kube-prometheus-stack` | The only service whose `secretGenerator` injects three files rather than one |

### Documentation naming mismatches

`reference/service-categories.md` names `loki`, `mimir`, `tempo`, `kube-prometheus-stack`, and `opentelemetry-kube-stack` as top-level services; all five exist only under `observability/`. It also names policy sets — `network-policies`, `rbac` — that have no corresponding directory, where `kyverno` on disk provides `policy-engine/` and `default-ruleset/`.

Separately, `reference/service-categories.md` currently fails the repository's own frontmatter audit (`hack/scripts/audit_doc_frontmatter.py`) for missing frontmatter, alongside `operations/entra-id-configuration-customer-guide.md`. Both are pre-existing and unrelated to the catalog work.

## Coupling and Blast Radius

The literal string `applications/base/services/<service>` couples three systems at three lifecycle stages. The stage determines how a path change fails.

| Stage | Consumer | Form | Failure mode |
|-------|----------|------|--------------|
| Compile time | `openCenter-cli` `internal/gitops/render_catalog.go` | ~23 Go string literals, plus templates under `internal/gitops/templates/` | Build or golden-test failure |
| Build time | `opencenter-gitops-enterprise` install overlays | ~23 files, `resources: github.com/.../openCenter-gitops-base//applications/base/services/<svc>?ref=main` | Kustomize build failure |
| Reconcile time | Rendered customer cluster trees | Flux `Kustomization` `spec.path`, with a per-service `GitRepository` source | **Silent breakage on a live cluster** |

Additional couplings:

- `opencenter-gitops-enterprise/scripts/set-base-ref.sh` matches on the regex prefix `//applications/base/services/`. A path move would cause it to stop rewriting refs without reporting an error.
- The per-service enterprise Components are **path-immune** — they patch by `HelmRelease` and `HelmRepository` name, not by path. What breaks them is renaming those Kubernetes resources.

### Rendered cluster pinning

15 or more real rendered cluster trees exist under the customer directories. Base-repository pinning is not uniform, and spans two GitHub organizations:

| Cluster | Organization | Ref |
|---------|--------------|-----|
| `opencenter-cloud/dev-vp` | `opencenter-cloud` | tag `2026.01` |
| Federal Farm Credit production clusters | `rackerlabs` | branch `main` |

Branch-tracking clusters would break on the commit that moves a path. Tag-pinned clusters break at the next tag bump. This asymmetry is the reason the catalog makes `path` a field and defers any move.

## CI Baseline in This Repository

Automation here is thin, which makes the catalog cheap to add and means its gates are the first structural checks in the repository rather than an extension of existing ones.

| Item | What it does |
|------|--------------|
| `.github/workflows/pre-commit.yaml` | The only workflow. Runs `pre-commit` against changed files |
| `.pre-commit-config.yaml` | `conventional-pre-commit`, `shellcheck`, `end-of-file-fixer`, `trailing-whitespace`, `check-yaml`, `black`, `yamllint` |
| `hack/scripts/` | Four scripts, all documentation-only: frontmatter audit, docs refresh, purpose-line insertion, AsciiDoc conversion |

There is no Makefile, no mise configuration, and no kustomize-build or manifest-validation gate. A new catalog file would be subject to `check-yaml` and `yamllint` and nothing else — no schema validation, and no check that a declared path exists.

## Testing Baseline in openCenter-cli

| Test | What it pins | Brittleness |
|------|--------------|-------------|
| `render_catalog_test.go` | Hardcodes `gateway` and `loki` `SourceName`, `BasePath`, and `GeneratedResourceFiles` | Those entries cannot change without editing tests; adding an unrelated service does not trip it |
| `relaypoint_parity_test.go` | Byte-level canonicalized comparison of every rendered file against `testdata/relaypoint-logistics-shared` | **The fixture does not exist on disk, so the test skips** |

There is therefore no byte-level safety net for a renderer refactor today. Regenerating that fixture from a known-good build is a prerequisite for the render-catalog convergence phase.

## Related

- [Service Catalog](index.md) — why the catalog exists
- [Catalog Schema](schema.md) — the schema derived from this baseline
- [Migration Plan](migration-plan.md) — how the defects above get fixed
- [Enterprise Components Pattern](../concepts/enterprise-components.md) — the path-immune rewrite mechanism
