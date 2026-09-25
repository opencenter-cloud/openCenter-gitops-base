# MetalLB – Base Configuration

This directory contains the **base manifests** for deploying [MetalLB](https://metallb.universe.tf/), a load-balancer implementation for bare-metal Kubernetes clusters.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/metallb.md).

**About MetalLB:**

- Provides **LoadBalancer service functionality** in environments without a native cloud load balancer (such as bare-metal or on-premise clusters).  
- Supports both **Layer 2** and **Layer 3** modes for flexible traffic routing.  
- Allows assigning external IPs to Kubernetes services to make them accessible outside the cluster.  
- Can advertise service IPs to upstream routers, enabling real network integration with minimal complexity.  
- Works seamlessly with ingress controllers and gateways such as **NGINX**, **Envoy Gateway**, or **HAProxy**.  
- Commonly used in hybrid or on-prem environments to provide reliable, production-grade service exposure.  
- Simplifies network configuration and improves accessibility for Kubernetes workloads in non-cloud environments.  

## Repository implementation

- Source path: `applications/base/services/metallb/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `metallb-system` and reads `metallb-values-base` plus the optional `metallb-values-override` Secret.
- Base values: `helm-values/values-0.16.1.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/metallb/` to validate the local manifests. The base installs MetalLB but does not define an `IPAddressPool` or advertisement. A consuming overlay must supply an address range and matching Layer 2 or BGP network configuration.
