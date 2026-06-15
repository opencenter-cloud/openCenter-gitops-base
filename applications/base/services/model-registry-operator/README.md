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
