# Operator Lifecycle Manager (OLM) - Base Configuration

This directory contains the **base manifests** for deploying the [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/), a Kubernetes component that manages installation, upgrade, and lifecycle of Operators.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/olm.md).

## Public Repository Scope

- This public repository contains the **base** OLM deployment backed by upstream public artifacts.
- If private manifest patches, private registry rewrites, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## OLM

- Installs and manages Operators using Kubernetes-native resources.
- Provides `CatalogSource`, `Subscription`, and `OperatorGroup` driven workflows.
- Handles Operator dependency resolution and upgrades.
- Supports internal and external operator catalogs.

## Repository implementation

- Source path: `applications/base/services/olm/`.
- Kustomize entrypoint: `kustomization.yaml`; it fetches the CRDs and OLM resources remotely from the upstream `v0.46.0` GitHub release (`crds.yaml` and `olm.yaml`). Rendering therefore depends on access to those remote release artifacts; the resources are not vendored in this directory.
- The pinned `v0.46.0` bootstrap resources include the `operatorhubio-catalog` `CatalogSource`, two OLM `OperatorGroup` resources, and the package-server CSV. These are runtime Kubernetes resources from the remote `olm.yaml`, not inventory metadata.
- Per-operator `Subscription` and `OperatorGroup` resources remain consumer-owned and are maintained by the individual service directories that install workload operators.

`catalog.yaml` is OpenCenter inventory metadata (`catalog.opencenter.dev/v1alpha1`, reporting version `v0.34.0` and `packaging: remoteKustomize`); it is not the runtime `CatalogSource`. The remote `v0.46.0` bootstrap installs the `operatorhubio-catalog`, while consuming services supply their own per-operator subscriptions and groups.

## Validation and limitations

Run `kustomize build applications/base/services/olm/` to validate the local manifests. The base bootstraps OLM and the upstream operatorhub catalog but does not install workload operators or approve their install plans. Consumer subscription configuration, namespace ownership, and install-plan approval remain cluster-specific concerns.
