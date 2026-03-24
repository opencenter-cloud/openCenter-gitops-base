# Loki – Base Configuration

This directory contains the **base manifests** for deploying [Grafana Loki](https://grafana.com/oss/loki/), a horizontally-scalable, highly-available log aggregation system designed for cloud-native environments.
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../../docs/reference/services/loki.md).

**About Grafana Loki:**

- Provides a **cost-effective log aggregation solution** optimized for storing and querying logs from Kubernetes clusters and applications.
- Deployed in **Simple Scalable mode** with separate read and write paths for high availability and horizontal scaling.
- Integrates natively with **OpenTelemetry** for log collection using OTLP protocol, eliminating the need for additional log shippers.
- Indexes only metadata (labels) rather than full-text, resulting in **significantly lower storage costs** compared to traditional solutions.
- Queries logs using **LogQL**, a query language similar to PromQL, enabling powerful filtering and aggregation.
- Supports **multi-tenancy**, **retention policies**, and **compaction** for efficient long-term log storage.
- Automatically integrates with **Grafana** for unified visualization of logs alongside metrics and traces.
- Commonly used for troubleshooting application issues, audit logging, security analysis, and operational insights.
