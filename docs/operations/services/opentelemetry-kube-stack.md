---
id: opentelemetry-kube-stack-config-guide
title: "OpenTelemetry Kube Stack Configuration Guide"
sidebar_label: OpenTelemetry
description: How to configure the OpenTelemetry kube stack in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [opentelemetry, observability, telemetry, kubernetes]
---

# OpenTelemetry Kube Stack Configuration Guide

**Purpose:** For platform engineers, operators, shows how to configure the OpenTelemetry kube stack in cluster repositories that consume the openCenter base.

Use this guide when a cluster repo needs to tune collector behavior or backend routing for the OpenTelemetry stack.

## What the Base Deploys

The base service deploys:

- `HelmRelease/opentelemetry-kube-stack`
- base values from the service `helm-values/` directory
- optional `Secret/opentelemetry-kube-stack-values-override`

Current base evidence: chart `opentelemetry-kube-stack` version `0.23.0`, with base values from `helm-values/values-0.23.0.yaml`. The shipped `daemon` collector is enabled as a DaemonSet, receives OTLP on ports `4317` and `4318`, exports logs to `observability-loki-gateway.observability.svc.cluster.local/otlp`, and exports traces to `observability-tempo-distributor.observability.svc.cluster.local:4317`.

## Common Cluster-Specific Configuration

Most clusters need to customize:

- collector endpoints and exposed services
- resource requests and limits
- exporters for Tempo, Loki, or external OTLP backends
- enrichment attributes such as cluster name or environment
- namespace or workload targeting for instrumentation

## Override Values Pattern

Example `override.yaml`:

```yaml
clusterName: <cluster-name>

collectors:
  daemon:
    mode: daemonset
```

Use the chart’s collector values to adjust pipelines rather than creating ad hoc collector resources unless the platform intentionally wants separate custom collectors.

## Pipeline Design Notes

- Keep traces flowing to Tempo over OTLP.
- Keep logs flowing to Loki through the intended write endpoint.
- Be deliberate with added resource attributes to avoid noisy labels.
- Sampling decisions belong close to the collector pipeline, not scattered across apps.

## Verification

```bash
kubectl get helmrelease -n observability opentelemetry-kube-stack
kubectl get pods -n observability
kubectl get opentelemetrycollectors -A
kubectl logs -n observability -l app.kubernetes.io/name=opentelemetry-operator
```

Healthy signs:

- operator and collector Pods are `Running`
- exporters connect successfully to Tempo and Loki
- traces and logs appear in Grafana

## Common Failure Modes

No telemetry arrives:
- verify exporter endpoints and service DNS names

Collectors use too many resources:
- reduce pipeline fan-out, batch sizes, or collection scope

Data lacks expected labels:
- check resource processors and cluster metadata injection

The endpoints above are repository defaults, not externally reachable URLs. The HelmRelease release name is `opentelemetry-kube-stack`; discover the collector Service exposing OTLP before configuring applications. A consumer that changes release names, namespaces, or collector topology must update application exporters and verification commands accordingly.

## Related Docs

- [OpenTelemetry Kube Stack Service Reference](../../reference/services/opentelemetry-kube-stack.md)
- [Tempo Reference](../../reference/services/tempo.md)
- [Loki Reference](../../reference/services/loki.md)
