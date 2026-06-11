---
id: service-triton-inference-server
title: "triton-inference-server"
sidebar_label: triton-inference-server
description: Reference for the Triton Inference Server service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, ML platform teams"
tags: [triton, nvidia, inference, model-serving, gpu]
---

# Triton Inference Server

**Purpose:** For platform engineers, ML platform teams, documents the NVIDIA Triton Inference Server service in openCenter-gitops-base.

`triton-inference-server` deploys NVIDIA Triton for high-performance, multi-framework model serving on GPU-accelerated Kubernetes nodes.

## What This Repo Deploys

- `Namespace/triton-inference-server`
- `HelmRelease/triton-inference-server`
- Base values Secret: `triton-inference-server-values-base`
- Optional override Secret: `triton-inference-server-values-override`

## When to Use It

- High-throughput, low-latency model inference is required with GPU acceleration.

## Example

```yaml
# Override values to configure model repository
image:
  imageName: nvcr.io/nvidia/tritonserver:26.05-py3
modelRepositoryServer: "10.0.1.50"
modelRepositoryPath: /exports/models
numGpus: 2
```

## Configuration Surfaces

- Service path: `applications/base/services/triton-inference-server/`
- Namespace: `triton-inference-server`
- Flux object: `HelmRelease/triton-inference-server`
- Source: `GitRepository/triton-inference-server` (tag `v2.69.0`)

## Upstream References

- [Triton Inference Server GitHub](https://github.com/triton-inference-server/server)
- [Triton deployment guide](https://github.com/triton-inference-server/server/tree/main/deploy/k8s-onprem)
- [Triton documentation](https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/index.html)
