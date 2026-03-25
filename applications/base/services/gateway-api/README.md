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
