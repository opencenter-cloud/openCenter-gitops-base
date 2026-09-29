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

**Purpose:** For platform engineers, operators, shows how to configure Loki in cluster repositories that consume the openCenter base.

Use this guide when a cluster repo needs to tune Loki or wire log collection into the observability stack.

## What the Base Deploys

The base service deploys:

- `HelmRelease/loki`
- base chart values from the service `helm-values/` directory
- optional `Secret/loki-values-override`
- optional final `Secret/opencenter-loki-secret` with key `values.yaml`

Current base evidence: chart `loki` version `7.3.0`, with values from `helm-values/values-7.3.0.yaml`. The base uses `SimpleScalable` mode, Swift as the schema object store, a 30-day retention period, replication factor 3, and a ClusterIP gateway enabled by default.

The Loki values store generated configuration as a Secret (`loki.configStorageType: Secret`), rather than a ConfigMap.

The `HelmRelease` applies values in order: chart defaults, `loki-values-base`,
`loki-values-override`, and finally `opencenter-loki-secret`. Later values
override earlier values. Both consumer Secrets are optional, so an absent
Secret is ignored. If `opencenter-loki-secret` is supplied, it must contain
the `values.yaml` data key. Add the label
`reconcile.fluxcd.io/watch: Enabled` to that Secret so Flux watches changes and
reconciles the HelmRelease.

The final Secret is supplied by the consumer or its CLI workflow; this base
does not create it. Updating or rolling back the HelmRelease does not remove a
stale final Secret, so an old `opencenter-loki-secret` can continue to
override rolled-back values until it is updated or deleted.

The base HelmRelease is named `loki`. Consumer overlays may render a namespace-prefixed release/service such as `observability-loki-gateway`; discover the actual Service in namespace `observability` before wiring clients. The repository OpenTelemetry default uses `observability-loki-gateway` as its internal endpoint.

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
       chunks: <chunks-container>
       ruler: <ruler-container>
       admin: <admin-container>
```

## Integration Notes

- If the platform uses `opentelemetry-kube-stack`, collector exporters usually point at the Loki gateway or write endpoint.
- Keep label design disciplined. Excessive cardinality is a common reason Loki becomes expensive or unstable.

## Verification

```bash
kubectl get helmreleases -n observability
kubectl get pods -n observability -l app.kubernetes.io/name=loki
kubectl logs -n observability -l app.kubernetes.io/name=loki --all-containers
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

The base contains no Swift credentials, container names, public hostname, or tenant credentials. Supply those in the consumer repo and keep sensitive values encrypted.

## Related Docs

- [Loki Service Reference](../../reference/services/loki.md)
