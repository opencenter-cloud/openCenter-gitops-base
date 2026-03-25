---
id: service-opentelemetry-kube-stack
title: "opentelemetry-kube-stack"
sidebar_label: opentelemetry-kube-stack
description: Reference for the OpenTelemetry Kube Stack service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, SREs"
tags: [opentelemetry, telemetry, observability]
---

# OpenTelemetry Kube Stack

`opentelemetry-kube-stack` provides collectors, operator support, and telemetry pipelines for traces and logs. It is the primary ingestion and processing layer for the observability stack in this repository.

## What This Repo Deploys

- `HelmRelease/opentelemetry-kube-stack`
- Base values from the service `helm-values/` directory
- Optional `opentelemetry-kube-stack-values-override`

## When to Use It

- You want a standard OTLP-based telemetry pipeline.
- You want Kubernetes-native collector deployment through the OpenTelemetry operator.
- You want logs and traces routed into Loki, Tempo, or other OTLP-capable backends.

## Key Integration Points

- Tempo is the main tracing backend.
- Loki is the main logging backend.
- Grafana and kube-prometheus-stack are typically used for visualization and alerting around collector health.

## Example

```yaml
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: cluster
spec:
  mode: daemonset
```

## Configuration Surfaces

- Service path: `applications/base/services/observability/opentelemetry-kube-stack/`
- Namespace: `observability`
- Flux object: `HelmRelease/opentelemetry-kube-stack`
- Base values Secret: `opentelemetry-kube-stack-values-base`
- Override values Secret: `opentelemetry-kube-stack-values-override`

## Related Docs

- [OpenTelemetry Kube Stack Configuration Guide](../../how-to/services/opentelemetry-kube-stack.md)
- [OpenTelemetry Notes](../../opentelemetry.md)

## Upstream References

- [OpenTelemetry docs](https://opentelemetry.io/docs/)
- [OpenTelemetry Operator docs](https://opentelemetry.io/docs/platforms/kubernetes/operator/)
- [OpenTelemetry Helm charts](https://github.com/open-telemetry/opentelemetry-helm-charts)
