---
id: opentelemetry-architecture
title: "OpenTelemetry Architecture Diagram"
sidebar_label: OTel Architecture
description: Conceptual view of the OpenTelemetry service path present in the observability catalog.
doc_type: explanation
audience: "platform engineers, operators"
tags: [opentelemetry, observability, architecture, telemetry]
---

# OpenTelemetry Architecture Diagram

**Purpose:** Show the repository-level relationship between the OpenTelemetry service and the other observability service paths. This is not a rendered-cluster topology.

## Implemented repository structure

The catalog defines `observability/opentelemetry-kube-stack` as a deployable child of the composite `observability` service. Its current base chart version is `0.23.0`, in namespace `observability`. The manifest-backed source is `HelmRepository/opentelemetry`, and the child `HelmRelease` uses `sourceRef.name: opentelemetry` for that source. The catalog fragment and generated lock instead record the source name as `open-telemetry`; this is catalog naming drift, not evidence that the service is deployed. The child has base values and an optional override Secret reference.

The same composite contains deployable paths for kube-prometheus-stack, Loki, Mimir, and Tempo, plus prerequisite namespace and source paths. Those paths are separate releases; the repository does not assert that every cluster enables all of them.

```text
                         consumer workload telemetry
                                   |
                                   v
              observability/opentelemetry-kube-stack
                 HelmRelease + base/optional values
                                   |
                 routing and exporters depend on values
                                   |
        +--------------------------+--------------------------+
        |                          |                          |
        v                          v                          v
   Tempo path                 Mimir path                 Loki path
   (traces)                  (metrics)                   (logs)
        \                          |                          /
         +------------ kube-prometheus-stack ---------------+
                      (Prometheus/Grafana/Alertmanager)
```

The arrows are conceptual relationships, not guaranteed exporter configuration. The checked-in values and Helm charts determine actual receivers, processors, exporters, storage, and dashboards for a selected deployment.

## Boundary and limitations

The repository does not contain application SDK configuration, a cluster-wide telemetry contract, or evidence that all observability children are enabled together. Consumers own workload instrumentation, override values, credentials, storage choices, and Flux activation. Use the service manifests and values as the authoritative deployment detail.

## Related

- [Architecture Explanation](architecture.md)
- [GitOps Workflow](gitops-workflow.md)
- [Service Catalog](../catalog/index.md)
