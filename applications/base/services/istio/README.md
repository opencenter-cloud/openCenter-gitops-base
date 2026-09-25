# Istio – Base Configuration

This directory contains the **base manifests** for deploying [Istio](https://istio.io/), a service mesh for securing, connecting, and observing microservices.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/istio.md).

**About Istio:**

- Provides **traffic management** with routing, retries, timeouts, and fault injection.  
- Enables **mTLS and zero-trust security** between services with policy enforcement.  
- Adds **observability** via telemetry, tracing, and access logs.  
- Supports **ingress and egress gateways** for controlled north-south traffic.  
- Works with standard Kubernetes services without app code changes.  
- Scales across namespaces and clusters with flexible sidecar injection.  
- Useful for platform teams, SREs, and developers operating complex service topologies.  

## Repository implementation

- Source path: `applications/base/services/istio/`.
- Kustomize stages: `namespace/`, `base/`, `istiod/`, and `gateway/`; `sources/` contains the HelmRepository resources. Apply the stages in the order encoded by the consuming overlay.
- Base values are in `base/helm-values/values-1.30.5.yaml`, `istiod/helm-values/values-1.30.5.yaml`, and `gateway/helm-values/values-1.30.5.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/istio/base/`, `kustomize build applications/base/services/istio/istiod/`, and `kustomize build applications/base/services/istio/gateway/` for the selected stages. The base does not inject sidecars into workloads, create `Gateway` routes, or supply certificates and mesh policy; those remain cluster/application configuration.
