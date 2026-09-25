# TrustyAI Service Operator – Base Configuration

This directory contains the **base manifests** for deploying the [TrustyAI Service Operator](https://github.com/opendatahub-io/trustyai-service-operator) via OLM.

## Public Repository Scope

- This public repository contains the **base** TrustyAI deployment backed by upstream public artifacts.
- If private catalog sources or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## TrustyAI Service Operator

- Provides AI explainability, fairness monitoring, and governance capabilities.
- Deploys TrustyAI services via the TrustyAIService custom resource.
- Computes SHAP, LIME, and counterfactual explanations for model predictions.
- Monitors model bias metrics (SPD, DIR) in production.
- Part of the Open Data Hub governance and observability stack.

## Prerequisites

- Kubernetes v1.26+.
- OLM (Operator Lifecycle Manager) deployed in the cluster.
- The `operatorhubio-catalog` CatalogSource available in the `olm` namespace.
- A model serving endpoint (KServe or ModelMesh) for explanation targets.

## Install Mechanism

This service uses OLM Subscription with `installPlanApproval: Manual` to give operators control over upgrades. After OLM creates an InstallPlan, it must be manually approved (or automated via cluster overlay).

## Repository implementation

- Source path: `applications/base/services/trustyai-service-operator/`.
- Kustomize entrypoint: `kustomization.yaml`; it renders the OperatorGroup, Subscription, and related OLM resources in the checked-in manifests. It does not create the `operatorhubio-catalog` CatalogSource.
- The Subscription's runtime `source` is `operatorhubio-catalog`; `catalog.yaml` is OpenCenter inventory metadata, not a Kubernetes CatalogSource. No Helm values file is used by this service.

## Validation and limitations

Run `kustomize build applications/base/services/trustyai-service-operator/` to validate the local manifests. OLM and a model-serving endpoint must exist in the target cluster. The base installs the operator but does not create a `TrustyAIService`, model endpoint, credentials, or monitoring policy.
