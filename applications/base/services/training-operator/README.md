# Training Operator (Kubeflow Trainer) – Base Configuration

This directory contains the **base manifests** for deploying the [Kubeflow Training Operator](https://github.com/kubeflow/trainer), the Kubernetes controller for distributed ML training jobs.

## Public Repository Scope

- This public repository contains the **base** Training Operator deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Training Operator

- Orchestrates distributed training jobs for PyTorch, TensorFlow, XGBoost, MPI, and JAX.
- Manages TrainJob custom resources with built-in support for job scheduling via Kueue.
- Supports fine-tuning LLMs with HuggingFace integration.
- Part of the Open Data Hub AI/ML training and compute stack.

## Prerequisites

- Kubernetes v1.28+.
- For GPU workloads: NVIDIA GPU Operator or equivalent.
- For job scheduling: Kueue (recommended).

## Common Overrides

| Parameter | Description | Default |
|-----------|-------------|---------|
| `controllerManager.image.repository` | Controller image | chart default |
| `controllerManager.image.tag` | Controller version | chart default |
| `controllerManager.resources.limits.memory` | Memory limit | `512Mi` |

## Repository implementation

- Source path: `applications/base/services/training-operator/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `kubeflow-system` and reads `training-operator-values-base` plus the optional `training-operator-values-override` Secret.
- Base values: `helm-values/values-0.0.1.yaml`; the OCI chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/training-operator/` to validate the local manifests. The base installs the Trainer controller but does not provide GPU drivers, training datasets, queues, or TrainJob resources. Kueue is recommended for admission but is not installed by this service.
