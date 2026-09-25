# Mimir – Base Configuration

This directory contains the **base manifests** for deploying [Grafana Mimir](https://grafana.com/oss/mimir/), a horizontally-scalable, highly-available metrics storage system designed for cloud-native environments.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../../docs/reference/services/mimir.md).

**About Grafana Mimir:**

- Provides a **centralized, multi-tenant metrics backend** fully compatible with Prometheus and PromQL.
- Designed for **high ingestion throughput** and **large-scale time-series storage** across multiple Kubernetes clusters.
- Stores long-term metrics in **object storage**, enabling **cost-efficient retention** and improved durability.
- Separates **read and write paths** to enable independent scaling for heavy queries or high ingestion workloads.
- Uses advanced **caching**, **sharding**, and **compaction** for efficient querying and optimized storage layout.
- Integrates natively with **Grafana** for unified visualization alongside logs and traces.

## Repository implementation

- Source path: `applications/base/services/observability/mimir/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `observability` and reads `mimir-values-base` plus the optional `mimir-values-override` Secret.
- Base values: `helm-values/values-6.2.0.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

> **Warning:** The active base values enable bundled standalone MinIO with root user `grafana-mimir` and root password `supersecret`. The active Mimir S3 object-storage configuration also sets `insecure: true`, using plaintext transport to MinIO. This is a development/insecure object-storage default, not a production credential or highly available object store. Override it with secured, production object storage and transport before use.

## Validation and limitations

Run `kustomize build applications/base/services/observability/mimir/` to validate the local manifests. The base actively configures the bundled MinIO storage above; tenant policy, retention overrides, external object-storage credentials, and Prometheus remote-write configuration remain cluster-specific. The base does not create Grafana dashboards or a metrics producer.
