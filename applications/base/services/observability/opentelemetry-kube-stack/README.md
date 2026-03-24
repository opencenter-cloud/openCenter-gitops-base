# OpenTelemetry Kube Stack – Base Configuration

This directory contains the **base manifests** for deploying the [OpenTelemetry Kube Stack](https://opentelemetry.io/), a **unified observability framework** for collecting, processing, and exporting **traces and logs** from Kubernetes workloads and infrastructure components.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../../docs/reference/services/opentelemetry-kube-stack.md).

---

## About OpenTelemetry Kube Stack

- Provides a **complete observability foundation** for Kubernetes clusters, integrating **traces and logs** under a single open standard.
- Deployed using the **OpenTelemetry Operator**, which manages collectors, instrumentation, and telemetry pipelines declaratively via Kubernetes manifests.
- Collects telemetry data from:
  - **Kubernetes system components** (API server, kubelet, scheduler, etc.)
  - **Application workloads** instrumented with OpenTelemetry SDKs or auto-instrumentation.
- Processes data through **OpenTelemetry Collectors**, which perform transformation, filtering, batching, and enrichment before export.
- Supports multiple backends including **Prometheus**, **Tempo**, **Loki**, **Grafana**, **Jaeger**, and **OTLP-compatible endpoints**.
- Enables **auto-discovery and dynamic configuration** for Kubernetes workloads, simplifying instrumentation and reducing manual setup.
- Designed for **scalability and resilience**, supporting both **agent** and **gateway** modes for distributed telemetry collection.
- Natively integrates with **Grafana** and other observability tools for unified dashboards and correlation between metrics, traces, and logs.
