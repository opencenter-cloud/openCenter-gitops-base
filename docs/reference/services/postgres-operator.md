---
id: service-postgres-operator
title: "postgres-operator"
sidebar_label: postgres-operator
description: Reference for the Zalando Postgres Operator service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [postgres, operator, database]
---

# Postgres Operator

**Purpose:** For platform engineers, operators, documents the Zalando Postgres Operator service in openCenter-gitops-base.

`postgres-operator` deploys the Zalando Postgres Operator for declarative PostgreSQL cluster management.

## What This Repo Deploys

- `Namespace/postgres-operator`
- `HelmRelease/postgres-operator`
- Base values Secret: `postgres-operator-values-base`
- Optional override Secret: `postgres-operator-values-override`

## When to Use It

- The platform wants PostgreSQL instances managed through Kubernetes custom resources.

## Example

```yaml
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  name: app-db
spec:
  teamId: platform
  numberOfInstances: 2
```

## Configuration Surfaces

- Service path: `applications/base/services/postgres-operator/`
- Namespace: `postgres-operator`
- Flux object: `HelmRelease/postgres-operator`
- Source: Zalando Postgres Operator Helm repository
- Source URL: `https://opensource.zalando.com/postgres-operator/charts/postgres-operator`
- Chart version: `2.0.2`

The base path installs the operator but does not create a PostgreSQL cluster. The example custom resource is consumer-owned and requires the operator's supported storage, access, and secret configuration.

## Upstream References

- [Postgres Operator docs](https://opensource.zalando.com/postgres-operator/)
- [Operator quickstart](https://opensource.zalando.com/postgres-operator/docs/quickstart.html)
