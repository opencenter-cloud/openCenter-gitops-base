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

## Repository implementation

- Source path: `applications/base/services/kuberay-operator/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `kuberay-system` and reads `kuberay-operator-values-base` plus the optional `kuberay-operator-values-override` Secret.
- Base values: `helm-values/values-1.7.1.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/kuberay-operator/` to validate the local manifests. The base installs the operator but does not create Ray clusters, jobs, services, GPU resources, or queues. Ray workloads require compatible node resources and should be defined in the consuming overlay.
