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
