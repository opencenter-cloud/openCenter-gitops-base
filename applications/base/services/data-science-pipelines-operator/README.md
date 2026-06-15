# Data Science Pipelines Operator – Base Configuration

This directory contains the **base manifests** for deploying the [Data Science Pipelines Operator](https://github.com/opendatahub-io/data-science-pipelines-operator) via OLM.

## Public Repository Scope

- This public repository contains the **base** DSP Operator deployment backed by upstream public artifacts.
- If private catalog sources or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Data Science Pipelines Operator

- Deploys and manages Kubeflow Pipelines v2 on Kubernetes.
- Provides ML pipeline orchestration for training, evaluation, and deployment workflows.
- Manages the pipeline API server, persistence agent, scheduler, and UI.
- Part of the Open Data Hub core services stack.

## Prerequisites

- Kubernetes v1.26+.
- OLM (Operator Lifecycle Manager) deployed in the cluster.
- The `operatorhubio-catalog` CatalogSource available in the `olm` namespace.
- Object storage (S3-compatible) for pipeline artifact storage.

## Install Mechanism

This service uses OLM Subscription with `installPlanApproval: Manual` to give operators control over upgrades. After OLM creates an InstallPlan, it must be manually approved (or automated via cluster overlay).
