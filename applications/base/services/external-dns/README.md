# ExternalDNS – Base Configuration

This directory contains the **base manifests** for deploying
[ExternalDNS](https://github.com/kubernetes-sigs/external-dns)
to synchronize exposed Kubernetes Services and Ingresses with DNS providers.

It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/external-dns.md).

## About ExternalDNS

- Synchronizes Kubernetes Service and Ingress resources with external DNS providers.
- Supports multiple providers including AWS Route 53, Cloudflare, Azure DNS, Google Cloud DNS, and many others.
- Uses a TXT ownership registry to track which records it manages.
- Operates in `upsert-only` mode by default (creates and updates but does not delete records).
- Watches configurable Kubernetes resource types (Services, Ingresses, Gateway API resources).
- Runs as a single-replica Deployment with leader election support for HA configurations.
