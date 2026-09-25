# Tempo – Base Configuration

This directory contains the **base manifests** for deploying [Grafana Tempo](https://grafana.com/oss/tempo/), a horizontally-scalable, distributed tracing backend designed for cloud-native environments.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../../docs/reference/services/tempo.md).

**About Grafana Tempo:**

- Provides a **highly scalable, cost-effective tracing solution** optimized for collecting and storing distributed traces from Kubernetes clusters and microservices.
- Deployed in **Distributed mode** with separate read and write paths for high availability and horizontal scaling.
- Integrates natively with **OpenTelemetry** for trace collection using the OTLP protocol, enabling seamless ingestion without additional agents.
- Stores trace data in **object storage** instead of databases, reducing operational overhead and storage costs.
- Persists incoming spans using a **Write-Ahead Log (WAL)** and periodically compacts data into **Parquet blocks** for efficient long-term retention.
- Supports querying through **TraceQL**, a query language purpose-built for filtering and analyzing trace data.
- Automatically integrates with **Grafana** for unified visualization of **traces, logs, and metrics**.

## Repository implementation

- Source path: `applications/base/services/observability/tempo/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `observability` and reads `tempo-values-base` plus the optional `tempo-values-override` Secret.
- Base values: `helm-values/hardened-values-1.61.3.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

The active base values enable both OTLP/HTTP and OTLP/gRPC receivers (gRPC port `4317`) and configure compactor block retention to `48h`.

## Validation and limitations

Run `kustomize build applications/base/services/observability/tempo/` to validate the local manifests. The base supplies the OTLP receivers and `48h` block-retention setting above; object-storage credentials and trace-producing workloads remain cluster-specific. The base does not configure Grafana data sources or OpenTelemetry instrumentation.
