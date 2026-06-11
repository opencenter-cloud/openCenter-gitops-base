# KServe – Base Configuration

This directory contains the **base manifests** for deploying
[KServe](https://kserve.github.io/website/docs/intro)
to provide model inference serving on Kubernetes.

It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/kserve.md).

## About KServe

- Provides a Kubernetes-native platform for serving predictive and generative AI models.
- Supports InferenceService CRD for declarative model deployment with autoscaling.
- Supports Standard mode (raw Kubernetes) and Knative mode (serverless scale-to-zero).
- Built-in model serving runtimes for common frameworks (TensorFlow, PyTorch, Triton, vLLM, etc.).
- Enables inference graphs for multi-model pipelines and model chaining.
- CNCF Incubating project.

## Prerequisites

- Kubernetes 1.30+.
- cert-manager 1.15+ (for webhook certificates).
- For Knative mode: Knative Serving + Istio networking layer.
- For Standard mode: no additional dependencies beyond cert-manager.
