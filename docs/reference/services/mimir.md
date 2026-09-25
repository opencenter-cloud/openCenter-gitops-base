---
id: service-mimir
title: "mimir"
sidebar_label: mimir
description: Reference for the Grafana Mimir service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, SREs"
tags: [mimir, metrics, observability]
---

# Mimir

**Purpose:** For platform engineers, operators, SREs, documents the Grafana Mimir service in openCenter-gitops-base.

`mimir` is the long-term and horizontally scalable metrics backend for the observability stack.

## What This Repo Deploys

- `HelmRelease/mimir`
- Base values Secret: `mimir-values-base`
- Optional override Secret: `mimir-values-override`

## When to Use It

- Prometheus retention in-cluster is not enough.
- Metrics from one or more clusters need durable object-storage-backed retention.

## Example

```yaml
prometheus:
  prometheusSpec:
    remoteWrite:
      - url: https://mimir.example.com/api/v1/push
```

## Configuration Surfaces

- Service path: `applications/base/services/observability/mimir/`
- Namespace: `observability`
- Flux object: `HelmRelease/mimir`
- Source: Grafana Helm repository
- Source URL: `https://grafana.github.io/helm-charts`
- Chart version: `6.2.0`

> **Important base-value warning:** The committed values actively enable the bundled MinIO subchart in `standalone` mode with root user `grafana-mimir` and root password `supersecret`. Mimir's generated internal object-storage configuration also uses insecure MinIO endpoints. Treat this as a development/default deployment, not production object storage. A consumer must use `mimir-values-override` to replace the root credential and preferably configure secured, durable external object storage before sending retained metrics to this service.

The base path does not create a Prometheus `remoteWrite` configuration. The example endpoint is consumer-owned and must match the deployed gateway or service exposure. Consumer-owned object-storage credentials, retention, tenancy, and endpoint configuration must be supplied through the override interface rather than relying on the committed MinIO defaults.

## Upstream References

- [Grafana Mimir docs](https://grafana.com/docs/mimir/latest/)
- [Mimir architecture docs](https://grafana.com/docs/mimir/latest/references/architecture/)
- [Mimir Helm chart](https://artifacthub.io/packages/helm/grafana/mimir-distributed)
