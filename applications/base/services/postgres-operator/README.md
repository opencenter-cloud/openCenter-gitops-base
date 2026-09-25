# Zalando Postgres Operator - Base Configuration

This directory contains the **base manifests** for deploying the [Zalando Postgres Operator](https://github.com/zalando/postgres-operator), a Kubernetes operator that automates PostgreSQL cluster lifecycle operations.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/postgres-operator.md).

## Public Repository Scope

- This public repository contains the **base** postgres-operator deployment backed by upstream public artifacts.
- If private image rewrites, private registry sourcing, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Zalando Postgres Operator

- Automates provisioning, scaling, and maintenance of PostgreSQL clusters on Kubernetes.
- Manages replicas and failover for high availability.
- Supports rolling updates and PostgreSQL version upgrades.
- Exposes declarative APIs via `postgresql` custom resources.
- Commonly used for platform services requiring managed PostgreSQL.

## Repository implementation

- Source path: `applications/base/services/postgres-operator/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `postgres-operator` and reads `postgres-operator-values-base` plus the optional `postgres-operator-values-override` Secret.
- Base values: `helm-values/values-2.0.2.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/postgres-operator/` to validate the local manifests. This deploys the operator but does not create a PostgreSQL cluster, database credentials, storage class, backup target, or connection pool. Those belong in the consuming workload/cluster configuration.
