---
id: tempo-config-guide
title: "Tempo Configuration Guide"
sidebar_label: Tempo
description: How to configure Tempo in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [tempo, tracing, observability, kubernetes]
---

# Tempo Configuration Guide

Use this guide when a cluster repo needs to tune the Tempo deployment or provide object storage configuration.

## What the Base Deploys

The base service deploys:

- `HelmRelease/tempo`
- base values from the service `helm-values/` directory
- optional `Secret/tempo-values-override`

## Common Cluster-Specific Configuration

Most clusters need to define:

- object storage backend and credentials
- retention period and compaction behavior
- scaling for distributors, ingesters, and queriers
- ingress / gateway exposure if Tempo query endpoints are externalized

## Override Values Pattern

Example `override.yaml`:

```yaml
storage:
  trace:
    backend: s3
    s3:
      bucket: tempo-traces
      region: us-east-1

traces:
  otlp:
    grpc:
      enabled: true
```

## Integration Notes

- Prefer OTLP from OpenTelemetry collectors instead of mixing many tracing protocols unless migration requires it.
- Verify the endpoint used by collectors matches the service exposed by the chart.

## Verification

```bash
kubectl get helmrelease -n observability tempo
kubectl get pods -n observability -l app.kubernetes.io/name=tempo
kubectl logs -n observability deploy/tempo-distributor
```

Healthy signs:

- distributor, ingester, querier, and compactor components are `Running`
- traces are visible in Grafana

## Common Failure Modes

Trace ingestion fails:
- verify collector exporter endpoint and service DNS name

Storage errors:
- verify object storage credentials, bucket names, and IAM / ACL settings

Trace queries are slow:
- review scaling and retention strategy, especially for large volumes

## Related Docs

- [Tempo Service Reference](../../reference/services/tempo.md)
