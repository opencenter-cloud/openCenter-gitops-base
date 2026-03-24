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
