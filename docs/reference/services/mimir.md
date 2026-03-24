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

## Upstream References

- [Grafana Mimir docs](https://grafana.com/docs/mimir/latest/)
- [Mimir architecture docs](https://grafana.com/docs/mimir/latest/references/architecture/)
- [Mimir Helm chart](https://artifacthub.io/packages/helm/grafana/mimir-distributed)
