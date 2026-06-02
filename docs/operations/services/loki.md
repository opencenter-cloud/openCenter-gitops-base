---
id: loki-config-guide
title: "Loki Configuration Guide"
sidebar_label: Loki
description: How to configure Loki in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [loki, logs, observability, kubernetes]
---

# Loki Configuration Guide

Use this guide when a cluster repo needs to tune Loki or wire log collection into the observability stack.

## What the Base Deploys

The base service deploys:

- `HelmRelease/loki`
- base chart values from the service `helm-values/` directory
- optional `Secret/loki-values-override`

The base does not create cluster-specific storage credentials or log shipping pipelines.

## Common Cluster-Specific Configuration

Most clusters need to configure:

- object storage backend and credentials
- retention and compaction behavior
- log ingestion path from OpenTelemetry or other collectors
- tenant strategy if multi-tenancy is needed
- ingress or gateway exposure for Grafana-to-Loki access, if externalized

## Override Values Pattern

Example `override.yaml`:

```yaml
loki:
  commonConfig:
    replication_factor: 2
  storage:
    type: s3
    bucketNames:
      chunks: loki-chunks
      ruler: loki-ruler
      admin: loki-admin
```

## Integration Notes

- If the platform uses `opentelemetry-kube-stack`, collector exporters usually point at the Loki gateway or write endpoint.
- Keep label design disciplined. Excessive cardinality is a common reason Loki becomes expensive or unstable.

## Verification

```bash
kubectl get helmrelease -n observability loki
kubectl get pods -n observability -l app.kubernetes.io/name=loki
kubectl logs -n observability deploy/loki-read
```

Healthy signs:

- write, read, and backend components are `Running`
- ingestion succeeds from collectors
- Grafana queries return expected logs

## Common Failure Modes

No logs arrive:
- verify the collector exporter endpoint and tenant headers

Writes fail:
- verify object storage credentials, bucket names, and network access

Queries are slow:
- reduce label cardinality and confirm read path scaling

## Related Docs

- [Loki Service Reference](../../reference/services/loki.md)
