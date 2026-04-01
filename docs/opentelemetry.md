---
id: opentelemetry-architecture
title: "OpenTelemetry Architecture Diagram"
sidebar_label: OTel Architecture
description: Visual architecture diagram showing the OpenTelemetry observability pipeline for Kubernetes workloads.
doc_type: explanation
audience: "platform engineers, operators"
tags: [opentelemetry, observability, architecture, telemetry]
---

# OpenTelemetry Architecture Diagram

**Purpose:** For platform engineers and operators, shows the high-level telemetry flow for workloads that send traces, metrics, and logs through the OpenTelemetry stack used with the openCenter observability platform.

This page is a conceptual diagram, not an exact manifest-level deployment reference. For service-specific configuration and operational details, use:

- [OpenTelemetry Kube Stack Configuration Guide](how-to/services/opentelemetry-kube-stack.md)
- [OpenTelemetry Kube Stack Service Reference](reference/services/opentelemetry-kube-stack.md)

## Diagram

```text
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                       │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│  │   Apps   │   │   Apps   │   │   Apps   │   │   Apps   │  │
│  │  (OTEL   │   │  (OTEL   │   │  (OTEL   │   │  (OTEL   │  │
│  │   SDK)   │   │   SDK)   │   │   SDK)   │   │   SDK)   │  │
│  └─────┬────┘   └─────┬────┘   └─────┬────┘   └─────┬────┘  │
│        │              │              │              │       │
└────────┼──────────────┼──────────────┼──────────────┼───────┘
         │              │              │              │
    ┌────▼──────────────▼──────────────▼──────────────▼──────┐
    │          OpenTelemetry Collector (DaemonSet)           │
    │         ┌─────────┐  ┌─────────┐  ┌─────────┐          │
    │         │ Traces  │  │ Metrics │  │  Logs   │          │
    │         │Receiver │  │Receiver │  │Receiver │          │
    │         └────┬────┘  └────┬────┘  └────┬────┘          │
    │              │            │            │               │
    │         ┌────▼────────────▼────────────▼────┐          │
    │         │      Processing Pipeline          │          │
    │         └────┬────────────┬────────────┬────┘          │
    │              │            │            │               │
    │         ┌────▼────┐  ┌────▼────┐  ┌────▼────┐          │
    │         │ Traces  │  │ Metrics │  │  Logs   │          │
    │         │Exporter │  │Exporter │  │Exporter │          │
    │         └─────────┘  └─────────┘  └─────────┘          │
    └─────────────┬────────────┬────────────┬────────────────┘
                  │            │            │
                  │       ┌────▼─────┐      │
                  │       │Prometheus│      │
                  │       │ Scraper  │      │
                  │       └────┬─────┘      │
                  │            │            │
          ┌───────▼────────────▼────────────▼──────┐
          │         Storage Layer                  │
          │  ┌──────────┐ ┌────────────┐ ┌────────┐│
          │  │  Traces  │ │ Metrics    │ │  Logs  ││
          │  │ Backend  │ │(Prometheus │ │Backend ││
          │  │          │ │   TSDB)    │ │        ││
          │  └──────────┘ └─────┬──────┘ └────────┘│
          └─────────────────────┼──────────────────┘
                                │
                          ┌─────▼──────┐
                          │AlertManager│
                          └─────┬──────┘
                                │
                          ┌─────▼───────┐
                          │Visualization│
                          │  (Grafana)  │
                          └─────────────┘
```

## How to Read This Diagram

- Applications emit telemetry through OpenTelemetry SDKs or compatible endpoints.
- OpenTelemetry collectors receive and process traces, metrics, and logs.
- Metrics are typically scraped or forwarded into the Prometheus-based metrics layer.
- Logs and traces are exported to the observability backends used by the platform.
- Grafana sits at the visualization layer for dashboards, exploration, and troubleshooting.

## Notes

- This diagram is intentionally simplified. Actual service composition, Helm values, and collector settings live under `applications/base/services/observability/opentelemetry-kube-stack/`.
- Depending on cluster configuration, exact routing and storage backends may vary.
