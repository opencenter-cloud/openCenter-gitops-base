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
