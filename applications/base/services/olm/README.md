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
