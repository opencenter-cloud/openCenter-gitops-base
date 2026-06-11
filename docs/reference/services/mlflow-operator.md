---
id: service-mlflow-operator
title: "mlflow-operator"
sidebar_label: mlflow-operator
description: Reference for the MLflow Operator service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, ML platform teams"
tags: [mlflow, operator, machine-learning, opendatahub]
---

# MLflow Operator

**Purpose:** For platform engineers, ML platform teams, documents the MLflow Operator service in openCenter-gitops-base.

`mlflow-operator` deploys the OpenDataHub MLflow Operator so MLflow instances can be managed declaratively in Kubernetes via Custom Resources.

## What This Repo Deploys

- `Namespace/opendatahub`
- `HelmRelease/mlflow-operator`
- Base values Secret: `mlflow-operator-values-base`
- Optional override Secret: `mlflow-operator-values-override`

## When to Use It

- MLflow should be operated as a platform service for experiment tracking, model registry, and artifact management.

## Example

```yaml
apiVersion: mlflow.opendatahub.io/v1
kind: MLflow
metadata:
  name: mlflow
spec:
  backendStoreUri: "sqlite:////mlflow/mlflow.db"
  registryStoreUri: "sqlite:////mlflow/mlflow.db"
  artifactsDestination: "file:///mlflow/artifacts"
  serveArtifacts: true
  storage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
```

## Configuration Surfaces

- Service path: `applications/base/services/mlflow-operator/`
- Namespace: `opendatahub`
- Flux object: `HelmRelease/mlflow-operator`
- Source: `GitRepository/mlflow-operator` (tag `1.1.0`)

## Upstream References

- [MLflow Operator GitHub](https://github.com/opendatahub-io/mlflow-operator)
- [MLflow documentation](https://mlflow.org/docs/latest/index.html)
