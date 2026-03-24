---
id: service-tempo
title: "tempo"
sidebar_label: tempo
description: Reference for the Tempo service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, SREs"
tags: [tempo, tracing, observability]
---

# Tempo

`tempo` is the distributed tracing backend in the observability stack. In this repository it is deployed as a Helm release in `observability` and is typically fed by OpenTelemetry collectors over OTLP.

## What This Repo Deploys

- `HelmRelease/tempo`
- Base values from the service `helm-values/` directory
- Optional `tempo-values-override`

## When to Use It

- You need central distributed trace storage.
- You want OTLP-native trace ingestion.
- You want Grafana and TraceQL-based query workflows.

## Key Integration Points

- OpenTelemetry collectors export traces to Tempo.
- Grafana queries Tempo for trace views and correlations.
- Object storage configuration is a major cluster-specific concern.

## Example

```yaml
exporters:
  otlp:
    endpoint: tempo.observability.svc.cluster.local:4317
```

## Configuration Surfaces

- Service path: `applications/base/services/observability/tempo/`
- Namespace: `observability`
- Flux object: `HelmRelease/tempo`
- Base values Secret: `tempo-values-base`
- Override values Secret: `tempo-values-override`

## Related Docs

- [Tempo Configuration Guide](../../how-to/services/tempo.md)

## Upstream References

- [Tempo docs](https://grafana.com/docs/tempo/latest/)
- [TraceQL docs](https://grafana.com/docs/tempo/latest/traceql/)
- [Tempo Helm chart](https://artifacthub.io/packages/helm/grafana/tempo-distributed)
