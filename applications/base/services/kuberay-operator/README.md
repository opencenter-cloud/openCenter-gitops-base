# KubeRay Operator – Base Configuration

This directory contains the **base manifests** for deploying the [KubeRay Operator](https://github.com/ray-project/kuberay), the Kubernetes operator for managing Ray clusters.

## Public Repository Scope

- This public repository contains the **base** KubeRay deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## KubeRay Operator

- Manages RayCluster, RayJob, and RayService custom resources.
- Enables distributed computing workloads for ML training, hyperparameter tuning, and model serving.
- Part of the Open Data Hub AI/ML training and compute stack.

## Prerequisites

- Kubernetes v1.26+.
- For GPU workloads: NVIDIA GPU Operator or equivalent.

## Common Overrides

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Operator image | `quay.io/kuberay/operator` |
| `image.tag` | Operator version | chart default |
| `resources.limits.memory` | Memory limit | `512Mi` |
