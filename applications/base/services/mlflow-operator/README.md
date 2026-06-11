# MLflow Operator (OpenDataHub) – Base Configuration

This directory contains the **base manifests** for deploying the [MLflow Operator](https://github.com/opendatahub-io/mlflow-operator) by OpenDataHub. It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

## Public Repository Scope

- This public repository contains the **base** MLflow deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## MLflow Operator

- Automates deployment and lifecycle management of MLflow on Kubernetes and OpenShift.
- Provides declarative CRD-based configuration for MLflow instances.
- Built-in Kubernetes auth with `self_subject_access_review` and in-pod TLS termination.
- Operator-managed database migrations (automatic scale-down, migrate, restore).
- Supports per-namespace artifact storage overrides via MLflowConfig CRD.
- Auto-creates NetworkPolicies and ServiceMonitors.
- Flexible storage: local PVC, PostgreSQL, S3-compatible artifact stores.

## Prerequisites

- Kubernetes v1.11.3+ (v1.26+ recommended).
- For OpenShift: service-ca-operator for automatic TLS certificates.
- For production: external PostgreSQL and S3-compatible object storage.

## Common Overrides

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.tag` | MLflow image version | chart default |
| `storage.size` | PVC size for local storage | `10Gi` |
| `storage.accessMode` | PVC access mode | `ReadWriteOnce` |
| `mlflow.corsAllowedOrigins` | CORS allowed origins | auto |
