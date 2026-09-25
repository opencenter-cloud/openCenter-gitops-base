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

**Purpose:** For platform engineers, operators, shows how to configure Tempo in cluster repositories that consume the openCenter base.

Use this guide when a cluster repo needs to tune the Tempo deployment or provide object storage configuration.

## What the Base Deploys

The base service deploys:

- `HelmRelease/tempo`
- base values from the service `helm-values/` directory
- optional `Secret/tempo-values-override`

Current base evidence: Helm chart `tempo-distributed` version `1.61.3`, with values from `helm-values/hardened-values-1.61.3.yaml`. The base values configure three ingesters, distributors, and queriers, plus a one-replica metrics generator; component services are `ClusterIP` by default.

The base HelmRelease is named `tempo`. Consumer overlays may render a namespace-prefixed service such as `observability-tempo-distributor`; discover the actual Service in namespace `observability` before configuring OTLP clients. The repository OpenTelemetry default uses `observability-tempo-distributor` for OTLP/gRPC.

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
       bucket: <trace-bucket>
       region: <object-storage-region>

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
kubectl get helmreleases -n observability
kubectl get pods -n observability -l app.kubernetes.io/name=tempo
kubectl logs -n observability -l app.kubernetes.io/name=tempo --all-containers
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

Object-storage credentials, bucket names, storage class, and any externally reachable query endpoint are consumer/environment-specific. The base does not provide them.

## Related Docs

- [Tempo Service Reference](../../reference/services/tempo.md)
