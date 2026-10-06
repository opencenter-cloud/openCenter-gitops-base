# Envoy Gateway API – Base Configuration

This directory contains the **base manifests** for deploying the [Envoy Gateway](https://gateway.envoyproxy.io/) as a managed service.
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/gateway-api.md).

## Public Repository Scope

- This public repository contains the **base** gateway-api deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

**About Envoy Gateway:**

- Implements the Kubernetes **Gateway API** to manage north-south traffic routing for services.  
- Simplifies Envoy deployment and configuration through a controller-based approach.
- Integrates seamlessly with **Cert-Manager** for automatic TLS certificate provisioning.  
- Supports advanced traffic management features such as path-based routing, header manipulation, timeouts, retries, and rate limiting.  
- Commonly used to expose applications, APIs, and services securely to external clients.  

## Repository implementation

- Source path: `applications/base/services/gateway-api/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `envoy-gateway-system` and reads `envoy-gateway-api-values-base` plus the optional `envoy-gateway-api-values-override` Secret.
- Base values: `helm-values/values-v1.9.2.yaml`; the OCI chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/gateway-api/` to validate the local manifests. This installs the Envoy Gateway controller but does not create `GatewayClass`, `Gateway`, routes, certificates, or an application endpoint. Configure those resources and the cluster's exposure mechanism in the consuming overlay.
