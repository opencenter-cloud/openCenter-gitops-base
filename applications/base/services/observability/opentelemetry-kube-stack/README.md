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

## Repository implementation

- Source path: `applications/base/services/observability/opentelemetry-kube-stack/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `observability` and reads `opentelemetry-kube-stack-values-base` plus the optional `opentelemetry-kube-stack-values-override` Secret.
- Base values: `helm-values/values-0.23.0.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

The active collector configuration receives OTLP over `0.0.0.0:4317` and `0.0.0.0:4318`, exports logs to `http://observability-loki-gateway.observability.svc.cluster.local/otlp`, and exports traces to `observability-tempo-distributor.observability.svc.cluster.local:4317`. The Tempo exporter explicitly uses insecure TLS; replace these endpoints and transport settings in an override when required by the cluster.

## Validation and limitations

Run `kustomize build applications/base/services/observability/opentelemetry-kube-stack/` to validate the local manifests. The base supplies the Loki and Tempo exporters above; authentication, sampling, workload instrumentation, and collector resource sizing remain cluster-specific. Review the insecure Tempo transport before production use.
