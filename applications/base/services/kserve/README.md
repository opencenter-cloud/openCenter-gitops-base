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

## Repository implementation

- Source path: `applications/base/services/kserve/`.
- Flux entrypoint: `kustomization.yaml`; the CRD HelmRelease is reconciled before the `kserve-resources` HelmRelease, which runs in `kserve` and reads `kserve-values-base` plus the optional `kserve-values-override` Secret.
- Base values: `helm-values/values-v0.18.0.yaml`; the OCI chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/kserve/` to validate the local manifests. This installs KServe resources but does not create `InferenceService` objects, model storage credentials, runtimes, Knative, or an ingress. Select Standard or Knative mode and configure serving workloads in a consuming overlay.
