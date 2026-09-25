# Model Registry Operator – Base Configuration

This directory contains the **base manifests** for deploying the [Model Registry Operator](https://github.com/opendatahub-io/model-registry-operator) via OLM.

## Public Repository Scope

- This public repository contains the **base** Model Registry Operator deployment backed by upstream public artifacts.
- If private catalog sources or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Model Registry Operator

- Provides a central registry for ML model versions, metadata, and lifecycle tracking.
- Implements the ML Metadata (MLMD) specification for model lineage.
- Exposes REST and gRPC APIs for model registration and querying.
- Part of the Open Data Hub core services stack.

## Prerequisites

- Kubernetes v1.26+.
- OLM (Operator Lifecycle Manager) deployed in the cluster.
- The `operatorhubio-catalog` CatalogSource available in the `olm` namespace.

## Install Mechanism

This service uses OLM Subscription with `installPlanApproval: Manual` to give operators control over upgrades. After OLM creates an InstallPlan, it must be manually approved (or automated via cluster overlay).

## Repository implementation

- Source path: `applications/base/services/model-registry-operator/`.
- Kustomize entrypoint: `kustomization.yaml`; it renders the OperatorGroup, Subscription, and related OLM resources in the checked-in manifests. It does not create the `operatorhubio-catalog` CatalogSource.
- The Subscription's runtime `source` is `operatorhubio-catalog`; `catalog.yaml` is OpenCenter inventory metadata, not a Kubernetes CatalogSource. No Helm values file is used by this service.

## Validation and limitations

Run `kustomize build applications/base/services/model-registry-operator/` to validate the local manifests. OLM and the selected catalog must exist in the target cluster. The base installs the operator but does not create a model registry instance, database, object storage, or user credentials.
