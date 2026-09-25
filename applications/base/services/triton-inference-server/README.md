# Triton Inference Server – Base Configuration

This directory contains the **base manifests** for deploying the
[NVIDIA Triton Inference Server](https://github.com/triton-inference-server/server)
for high-performance AI/ML model serving on Kubernetes.

It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/triton-inference-server.md).

## About Triton Inference Server

- Cloud-native inference serving solution optimized for both CPUs and GPUs.
- Supports multiple ML frameworks: TensorRT, TensorFlow, PyTorch, ONNX, vLLM, Python, and more.
- Provides HTTP/REST and gRPC endpoints for inference requests.
- Features dynamic batching, model ensembles, and concurrent model execution.
- Built-in metrics (Prometheus) for autoscaling and observability.
- Supports MIG, multi-GPU, and multi-node inference deployments.

## Prerequisites

- Kubernetes cluster with NVIDIA GPU Operator deployed.
- Model repository accessible via NFS, S3, GCS, or Azure Storage.
- Prometheus (optional, for autoscaling based on queue metrics).

## Repository implementation

- Source path: `applications/base/services/triton-inference-server/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `triton-inference-server` and reads `triton-inference-server-values-base` plus the optional `triton-inference-server-values-override` Secret.
- Base values: `helm-values/values-v2.72.0.yaml`; chart source metadata is in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/triton-inference-server/` to validate the local manifests. The base does not provide a model repository, model files, GPU capacity, ingress, or autoscaling policy. Configure model storage and serving resources through the cluster/application override.
