---
id: service-loki
title: "loki"
sidebar_label: loki
description: Reference for the Loki service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, SREs"
tags: [loki, logs, observability]
---

# Loki

`loki` is the centralized log store in the observability stack. In this repository it is deployed as a Helm release in the `observability` namespace.

## What This Repo Deploys

- `HelmRelease/loki`
- Base values from the service `helm-values/` directory
- Optional `loki-values-override`

## When to Use It

- You want centralized application and platform logs.
- You want a log backend that integrates cleanly with Grafana and OpenTelemetry.
- You want label-based querying through LogQL instead of full-text indexing.

## Key Integration Points

- OpenTelemetry collectors or Promtail-style agents forward logs to Loki.
- Grafana provides the primary query and visualization interface.
- Object storage and retention policy are major cluster-specific decisions.

## Example

```logql
{namespace="harbor"} |= "error"
```

## Configuration Surfaces

- Service path: `applications/base/services/observability/loki/`
- Namespace: `observability`
- Flux object: `HelmRelease/loki`
- Base values Secret: `loki-values-base`
- Override values Secret: `loki-values-override`
- Source: Grafana Helm repository

## Related Docs

- [Loki Configuration Guide](../../how-to/services/loki.md)

## Upstream References

- [Loki docs](https://grafana.com/docs/loki/latest/)
- [LogQL docs](https://grafana.com/docs/loki/latest/query/)
- [Loki Helm chart](https://artifacthub.io/packages/helm/grafana/loki)
