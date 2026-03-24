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

## Upstream References

- [Postgres Operator docs](https://opensource.zalando.com/postgres-operator/)
- [Operator quickstart](https://opensource.zalando.com/postgres-operator/docs/quickstart.html)
