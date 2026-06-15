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
