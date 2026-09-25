# vLLM – Base Configuration

This directory contains the **base manifests** for deploying
[vLLM Production Stack](https://github.com/vllm-project/production-stack)
to provide high-throughput LLM inference serving on Kubernetes.

It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/vllm.md).

## About vLLM

- High-throughput, memory-efficient LLM inference engine with PagedAttention
- OpenAI-compatible API server for drop-in replacement of proprietary endpoints
- Production Stack adds request routing, autoscaling, and multi-model serving on Kubernetes
- Supports NVIDIA and AMD GPUs with tensor parallelism for large models
- Continuous batching maximizes GPU utilization under concurrent request load

## Prerequisites

- NVIDIA GPU Operator deployed and GPU nodes available (see `nvidia-gpu-operator/`)
- A model accessible from the cluster (HuggingFace Hub, S3, or PVC-backed storage)
- Cluster-specific override secret (`vllm-values-override`) specifying at minimum the model to serve and GPU resource requests

## Repository implementation

- Source path: `applications/base/services/vllm/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `vllm` and reads `vllm-values-base` plus the required cluster-specific `vllm-values-override` Secret.
- Base values: `helm-values/values-0.1.12.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/vllm/` to validate the local manifests. The base does not choose a model, provide GPU capacity, create model credentials, or expose an API endpoint. A serving deployment is not useful until the override supplies model and resource settings and the cluster provides compatible GPU support.
