---
id: migration-olmv0-to-olmv1
title: "Migration Plan: OLM v0 to OLM v1"
sidebar_label: OLM v0 to v1 Migration
description: Plan for moving services from OLM v0 (operator-lifecycle-manager) to OLM v1 (operator-controller), including blockers, decisions, repository changes, cluster cutover, and OLM v0 decommissioning.
doc_type: explanation
audience: "platform engineers, cluster operators, maintainers"
tags: [olm, operators, migration, plan, clusterextension]
---

# Migration Plan: OLM v0 to OLM v1

**Purpose:** Plan the move from OLM v0 ([operator-lifecycle-manager](https://github.com/operator-framework/operator-lifecycle-manager)) to OLM v1 ([operator-controller](https://github.com/operator-framework/operator-controller)) for the services in this repository and the clusters that consume them.

**Status:** Proposed. Nothing in this plan is implemented yet. The research reflects operator-controller `v1.12.0`, the latest stable release as of October 2026.

## Summary

OLM v1 is not a like-for-like replacement for OLM v0, so this is a decision about how each operator should be installed, not a mechanical API swap.

- **Keycloak** is the only operator in this repository that OLM v1 can install directly from the operatorhub.io catalog, and only with an alpha feature flag turned on.
- **The four AI/ML operators** (`model-registry-operator`, `trustyai-service-operator`, `feast-operator`, `data-science-pipelines-operator`) are not published in the operatorhub.io catalog. They need a different install method whatever OLM version is used.
- **OLM v1 cannot take over an operator already installed by OLM v0.** Each operator is cut over by removing the v0 objects and reinstalling. This usually means deleting the operator's CRDs, which also deletes every resource of those types.

## Current state in this repository

### OLM v0 install

| Item | Value |
|---|---|
| Path | `applications/base/services/olm/` |
| Install method | Remote Kustomize: `crds.yaml` and `olm.yaml` from the upstream release |
| Pinned version | `v0.46.0`, from `olm/kustomization.yaml` |
| Version drift | `olm/catalog.yaml` and `docs/reference/service-categories.md` still say `v0.34.0` |
| Namespace | `olm` |
| Catalog | `operatorhubio-catalog` CatalogSource, created by the upstream `olm.yaml` and not written in this repository |
| Blueprints | `operator-infrastructure` (required), `enterprise` (recommended) |

### Services that install through OLM v0

All five use `installPlanApproval: Manual`, the source `operatorhubio-catalog` in the `olm` namespace, and an OperatorGroup that watches a single namespace.

| Service | Package | Channel | Namespace | Notes |
|---|---|---|---|---|
| `keycloak/10-operator` | `keycloak-operator` | `fast` | `keycloak` | `startingCSV: keycloak-operator.v26.4.2` |
| `model-registry-operator` | `model-registry-operator` | `alpha` | `opendatahub` | |
| `trustyai-service-operator` | `trustyai-service-operator` | `alpha` | `opendatahub` | |
| `feast-operator` | `feast-operator` | `alpha` | `opendatahub` | |
| `data-science-pipelines-operator` | `data-science-pipelines-operator` | `alpha` | `opendatahub` | |

Other findings:

- No Subscription sets `spec.config` (env, resources, nodeSelector, tolerations), so nothing like that has to be carried over.
- Nothing in this repository approves InstallPlans. Approval is a manual step on the cluster.
- No Flux `Kustomization` objects are committed here. Ordering is expressed through `requires:` in `catalog.yaml`, and Flux examples exist only in docs.
- The only custom resource in this repository that depends on an operator's CRDs is the `Keycloak` CR in `keycloak/20-keycloak/`, followed by `25-theme` and `30-oidc-rbac`.
- No NetworkPolicy, Kyverno, or PSA rules in this repository target the OLM namespaces.
- The packaging type `olmSubscription` is defined in `applications/catalog.schema.json` (top level and `subcomponents[]`) and handled in `hack/scripts/catalog.py` (`valid_pkg` and `_entry_version`).

### Outside this repository

These also need changes but are not in this checkout:

- **openCenter-cli** renders the cluster-side Flux Kustomizations for OLM and for `keycloak-operator`, including `dependsOn` and the NetworkPolicy patches.
- **Upstream NetworkPolicy port.** The OLM v0 upstream NetworkPolicies hard-code API server port `6443`, so clusters whose API port is different (for example `443`) need patches. This includes the per-CatalogSource `*-unpack-bundles` policy that OLM v0 generates at runtime.
- **Private enterprise repository.** It holds OLM enterprise assets and replaces upstream images with images from an internal registry.
- **Limited internet access.** Some clusters have limited internet access, so remote GitHub manifest URLs and `quay.io` images must be mirrored.

## OLM v1 facts that shape the plan

| # | Topic | OLM v1 behavior | Source |
|---|---|---|---|
| 1 | Install modes | An operator must support watching all namespaces (`AllNamespaces`). Watching a single namespace or the operator's own namespace needs the alpha feature flag `SingleOwnNamespaceInstallSupport` (off by default) and `spec.config.inline.watchNamespace`. Only one operator can own a given CRD across the cluster. | [Limitations](https://operator-framework.github.io/operator-controller/project/olmv1_limitations/), [features.go](https://github.com/operator-framework/operator-controller/blob/main/internal/operator-controller/features/features.go) |
| 2 | Keycloak package | The published `keycloak-operator` 26.5.0 package supports only `OwnNamespace` and `SingleNamespace`, not `AllNamespaces`. | [CSV](https://github.com/k8s-operatorhub/community-operators/tree/main/operators/keycloak-operator) |
| 3 | AI/ML packages | `feast-operator`, `trustyai-service-operator`, `model-registry-operator`, `data-science-pipelines-operator`, and `opendatahub-operator` are not in `k8s-operatorhub/community-operators`, which is what `quay.io/operatorhubio/catalog` is built from. `opendatahub-operator` is published only in Red Hat's OpenShift catalog. | [community-operators](https://github.com/k8s-operatorhub/community-operators/tree/main/operators) |
| 4 | Installer service account | `spec.serviceAccount` is deprecated and ignored in `v1.12.0`. operator-controller runs as cluster-admin, so anyone who can write a ClusterExtension effectively has cluster-admin. Access is controlled with RBAC on the ClusterExtension API, plus a ValidatingAdmissionPolicy for finer limits. | [clusterextension_types.go](https://github.com/operator-framework/operator-controller/blob/v1.12.0/api/v1/clusterextension_types.go), [API access how-to](https://github.com/operator-framework/operator-controller/blob/main/docs/howto/how-to-protect-olmv1-api-access.md) |
| 5 | Manual approval | There is no InstallPlan. Manual approval becomes an exact `version` pin in Git, and an upgrade is a commit that changes it. | [Upgrade support](https://operator-framework.github.io/operator-controller/concepts/upgrade-support/) |
| 6 | Adoption | There is no official way to take over an existing install. CRDs that already exist on the cluster are not adopted cleanly. | [OLM v1 docs](https://operator-framework.github.io/operator-controller/), [oadp-operator#2160](https://github.com/openshift/oadp-operator/pull/2160) |
| 7 | Coexistence | v0 (`olm` namespace) and v1 (`olmv1-system`) can run at the same time, but cannot both manage the same operator. | Same as above |
| 8 | cert-manager | operator-controller requires cert-manager. `install.sh` also installs cert-manager, so do not use it. Apply the `operator-controller.yaml` release manifest and make it depend on this repository's `cert-manager` service. Webhook support through cert-manager is GA and on by default. | [Getting started](https://operator-framework.github.io/operator-controller/getting-started/olmv1_getting_started/) |
| 9 | Catalogs | The standard install does not create a catalog. A `ClusterCatalog` for operatorhub.io must be created explicitly. | Same as above |
| 10 | Other gaps | No dependency resolution between operators. No `APIService` support. No `OperatorConditions` support. The `Subscription.spec.config` equivalent (`DeploymentConfig`) is an alpha flag. Only `registry+v1` bundles are supported; Helm chart bundles are not implemented. | [Limitations](https://operator-framework.github.io/operator-controller/project/olmv1_limitations/), [#962](https://github.com/operator-framework/operator-controller/issues/962) |
| 11 | Health checks | ClusterExtension reports `Installed` and `Progressing`; ClusterCatalog reports `Serving` and `Progressing`. Flux's default status logic looks for `Ready`, so it can mark these resources healthy too early. Use `healthCheckExprs`. | [ClusterExtension API](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/operatorhub_apis/clusterextension-olm-operatorframework-io-v1) |
| 12 | No bundle-unpack Jobs | OLM v1 does not run per-CatalogSource bundle-unpack Jobs, so the generated `*-unpack-bundles` NetworkPolicy problem goes away. catalogd and operator-controller still need API server and registry access. | Verify against the `operator-controller.yaml` manifest |

## Phase 0: decisions and verification

### Decisions

| # | Decision | Options | Recommendation |
|---|---|---|---|
| D1 | The four AI/ML operators | **A.** Install them from each project's own release manifests or Helm chart. This repository already supports that shape, for example `mlflow-operator` uses `gitRepository`. **B.** Install `opendatahub-operator` from a custom catalog (OpenShift-focused, needs a Red Hat registry). **C.** Remove them from the base. | **A**, after confirming what is running today. |
| D2 | Keycloak | **A.** OLM v1 with `SingleOwnNamespaceInstallSupport` turned on. **B.** Keycloak's own published manifests, without OLM. | **B** if production must avoid alpha features, otherwise **A**. |
| D3 | Keep OLM at all | If D1 is A and D2 is B, nothing in the base needs OLM v1. | Keep OLM v1 only if downstream clusters need it. |
| D4 | Upgrade approval | Exact `version` pin, or a version range. | Exact pin, which matches today's Manual approval. |

### Checks on each live cluster

Run these before choosing D1 and D2:

```bash
# Can the AI/ML packages resolve from the current catalog?
kubectl get packagemanifests -n olm | grep -E 'feast|trustyai|model-registry|data-science'

# What is actually installed, and at which version?
kubectl get subscriptions,csv -A
kubectl get subscription -n opendatahub -o yaml   # look at status.conditions

# Which operator CRDs exist?
kubectl get crd | grep -E 'keycloak|feast|trustyai|modelregistr|datasciencepipelines'
```

Record the Keycloak CSV version that is actually running. It may be newer than `v26.4.2` if InstallPlans were approved after the initial install.

**Exit criteria:** D1 to D4 decided, and the live inventory recorded for every cluster.

## Phase 1: repository changes

These changes do not affect any cluster.

1. **Fix the version drift.** Change `v0.34.0` to `v0.46.0` in `applications/base/services/olm/catalog.yaml` and `docs/reference/service-categories.md`.

2. **Add a new service** `applications/base/services/operator-controller/`:

   ```yaml
   # kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - https://github.com/operator-framework/operator-controller/releases/download/v1.12.0/operator-controller.yaml
     - clustercatalog-operatorhubio.yaml
   patches:
     # Only if D2 = A. Check the container index before relying on /containers/0.
     - target:
         kind: Deployment
         name: operator-controller-controller-manager
         namespace: olmv1-system
       patch: |-
         - op: add
           path: /spec/template/spec/containers/0/args/-
           value: --feature-gates=SingleOwnNamespaceInstallSupport=true
   ```

   ```yaml
   # clustercatalog-operatorhubio.yaml
   apiVersion: olm.operatorframework.io/v1
   kind: ClusterCatalog
   metadata:
     name: operatorhubio
   spec:
     source:
       type: Image
       image:
         # Pin by digest. pollIntervalMinutes cannot be combined with a digest.
         ref: quay.io/operatorhubio/catalog@sha256:<digest>
   ```

   Give it a `catalog.yaml` with `packaging: remoteKustomize`, `namespace: olmv1-system`, and `requires: [cert-manager]`. Add it to the `operator-infrastructure` and `enterprise` blueprints.

3. **Add a packaging type `clusterExtension`:**
   - `applications/catalog.schema.json`: add it to the `packaging` enum at the top level and under `subcomponents[]`.
   - `hack/scripts/catalog.py`: add it to `valid_pkg`, and have `_entry_version` print the pinned version instead of `OLM`.

4. **If D2 = A, rework Keycloak `10-operator`.** Replace `subscription.yaml` and `operatorgroup.yaml` with:

   ```yaml
   apiVersion: olm.operatorframework.io/v1
   kind: ClusterExtension
   metadata:
     name: keycloak-operator
     annotations:
       # Deleting a ClusterExtension uninstalls the operator, including its CRDs
       # and every Keycloak CR. Do not let Flux prune it.
       kustomize.toolkit.fluxcd.io/prune: disabled
   spec:
     namespace: keycloak            # must already exist; OLM v1 does not create it
     config:
       configType: Inline
       inline:
         watchNamespace: keycloak
     source:
       sourceType: Catalog
       catalog:
         packageName: keycloak-operator
         channels: ["fast"]
         version: "26.4.2"          # the version recorded on the live cluster
         selector:
           matchLabels:
             olm.operatorframework.io/metadata.name: operatorhubio
   ```

   Update `keycloak/catalog.yaml` so `10-operator` uses `packaging: clusterExtension` and `requires: [operator-controller]`.

5. **Rework the AI/ML operators** according to D1.

6. **Update the docs:**
   - Rewrite [OLM Service Onboarding](olm-service-onboarding.md) for ClusterExtension.
   - Update `docs/reference/services/olm.md`, `docs/operations/services/keycloak.md`, `docs/operations/version-upgrade-guide.md`, `docs/operations/service-deployment-patterns.md`, `docs/catalog/schema.md`, `docs/catalog/current-state.md`, `docs/concepts/architecture.md`, `docs/concepts/gitops-workflow.md`, `docs/concepts/security-model.md`, `docs/index.md`, the root `README.md`, and the service READMEs.
   - Add this Flux health check example:

   ```yaml
   healthCheckExprs:
     - apiVersion: olm.operatorframework.io/v1
       kind: ClusterExtension
       current: status.conditions.exists(e, e.type == 'Installed' && e.status == 'True')
       failed: status.conditions.exists(e, e.type == 'Progressing' && e.status == 'False')
     - apiVersion: olm.operatorframework.io/v1
       kind: ClusterCatalog
       current: status.conditions.exists(e, e.type == 'Serving' && e.status == 'True')
   ```

7. **Keep the OLM v0 parts for now.** Leave the `olm` service and the `olmSubscription` type in place, and mark them deprecated.

8. **Coordinate outside this repository:**
   - openCenter-cli: Flux Kustomizations, `dependsOn`, and any NetworkPolicy patches for `olmv1-system`.
   - Private enterprise repository: internal-registry image overrides for operator-controller, catalogd, the catalog image, and bundle images.
   - Clusters with limited internet access: mirror the release manifest and images.

**Exit criteria:** `kustomize build` passes for every changed path, catalog validation and docs generation pass, and the docs are consistent.

## Phase 2: install OLM v1 alongside v0 in a non-production cluster

1. Deploy `operator-controller` with a Flux dependency on `cert-manager`.
2. Check that the NetworkPolicies in `operator-controller.yaml` allow API server access on clusters whose API port is not `6443`.

```bash
kubectl -n olmv1-system get deploy
kubectl wait --for=condition=Serving=True clustercatalog/operatorhubio --timeout=300s
```

**Exit criteria:** `catalogd-controller-manager` and `operator-controller-controller-manager` are Available, `clustercatalog/operatorhubio` reports `Serving=True`, and the existing cert-manager install is unchanged.

## Phase 3: rehearse each operator's cutover

Start with Keycloak in a non-production cluster.

1. **Back up:**
   - a Postgres dump of the Keycloak database;
   - the Keycloak custom resources: `kubectl get keycloaks,keycloakrealmimports -A -o yaml > keycloak-crs.yaml`.
2. **Suspend** the Flux Kustomizations for `keycloak-operator` and `keycloak-cr`.
3. **Remove the v0 objects:** delete the Subscription, the CSV, and the OperatorGroup in the `keycloak` namespace.
4. **Test whether OLM v1 can install over the existing CRDs.** If the ClusterExtension reports a conflict, delete the Keycloak CRDs. That deletes the `Keycloak` CR and its StatefulSet. The data stays in Postgres.
5. **Merge the ClusterExtension and resume `keycloak-operator`.** Wait for `Installed=True` and for the `keycloak-operator` Deployment to be Available.
6. **Resume `keycloak-cr`.** Check the StatefulSet, login, and OIDC.
7. **Record the downtime.**

**Rollback:** delete the ClusterExtension and re-apply the v0 Subscription. Deleting the ClusterExtension removes the CRDs and CRs again, so rollback is also disruptive.

Repeat for the AI/ML operators if D1 keeps OLM, or switch them to their new packaging.

**Exit criteria:** a written runbook with measured downtime and a tested rollback, for each operator.

## Phase 4: production rollout

- Roll out one cluster at a time, with one operator per maintenance window, using the Phase 3 runbook.
- From then on, an upgrade is a pull request that changes `spec.source.catalog.version`, together with the catalog digest if needed.

## Phase 5: remove OLM v0

1. **Check that nothing still depends on OLM v0.** `kubectl get subscriptions,csv -A` must show nothing outside `olm` except `packageserver`. Any v0 operator still installed would be garbage-collected once the v0 CRDs are deleted.
2. **Remove the v0 install.** Take `olm` out of the blueprints and let Flux prune the OLM Kustomization.
3. **Check for leftovers:**
   - the `olm` and `operators` namespaces;
   - the `operators.coreos.com` CRDs;
   - the APIService `v1.packages.operators.coreos.com`. If it is left with nothing behind it, API discovery breaks for kubectl and Flux.

   ```bash
   kubectl get ns olm operators
   kubectl get crd | grep operators.coreos.com
   kubectl get apiservice v1.packages.operators.coreos.com
   ```

4. **Clean up the repository:** delete `applications/base/services/olm/`, remove the `olmSubscription` packaging type, and update or remove the remaining v0 docs.

## Risks

| Risk | Mitigation |
|---|---|
| Deleting a CRD deletes every resource of that type | Back up first, cut over in maintenance windows, and set `kustomize.toolkit.fluxcd.io/prune: disabled` on ClusterExtensions |
| Depending on the alpha `SingleOwnNamespaceInstallSupport` flag | Choose D2 = B, or pin the operator-controller version and re-test on every upgrade |
| Write access to ClusterExtension is effectively cluster-admin | Limit write access to the Flux service account. Optionally add a ValidatingAdmissionPolicy that allows only specific packages and namespaces. |
| A catalog stops serving the pinned version | Pin the catalog image by digest and bump catalog and version together |
| Flux reports a ClusterExtension healthy too early | Use the `healthCheckExprs` above |
| Upstream NetworkPolicies assume API port `6443` | Check the `olmv1-system` policies in Phase 2 and patch them through openCenter-cli if needed |
| Clusters with limited internet access cannot reach GitHub or `quay.io` | Mirror the release manifest, controller images, catalog image, and bundle images. Override them in the private enterprise repository. |

## Open questions

- Do the `healthCheckExprs` above work on the Flux version in use? They need Flux 2.5 or later.
- What exactly does OLM v1 do when the operator's CRDs already exist? Phase 3 step 4 answers this.
- Is the operator-controller container at index `0` in the Deployment patch?
- Does the live catalog's Keycloak package still lack `AllNamespaces` at migration time?
- How does operator-controller get configured to pull bundle images through an internal registry mirror on clusters with limited internet access?

## Related documents

- [OLM Service Onboarding](olm-service-onboarding.md)
- [Service Deployment Patterns](service-deployment-patterns.md)
- [Version Upgrade Guide](version-upgrade-guide.md)
- [OLM service reference](../reference/services/olm.md)
- [Catalog schema](../catalog/schema.md)
