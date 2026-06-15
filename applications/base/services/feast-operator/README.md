# Feast Operator – Base Configuration

This directory contains the **base manifests** for deploying the [Feast Operator](https://github.com/opendatahub-io/feast) via OLM.

## Public Repository Scope

- This public repository contains the **base** Feast Operator deployment backed by upstream public artifacts.
- If private catalog sources or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Feast Operator

- Deploys and manages Feast feature store instances on Kubernetes.
- Provides consistent feature serving for training and inference workloads.
- Manages the Feast registry, online store, and offline store components.
- Part of the Open Data Hub governance and observability stack.

## Prerequisites

- Kubernetes v1.26+.
- OLM (Operator Lifecycle Manager) deployed in the cluster.
- The `operatorhubio-catalog` CatalogSource available in the `olm` namespace.

## Install Mechanism

This service uses OLM Subscription with `installPlanApproval: Manual` to give operators control over upgrades. After OLM creates an InstallPlan, it must be manually approved (or automated via cluster overlay).
