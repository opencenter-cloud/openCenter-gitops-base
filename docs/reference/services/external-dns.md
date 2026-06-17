---
id: service-external-dns
title: "external-dns"
sidebar_label: external-dns
description: Reference for the external-dns service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [dns, external-dns, ingress, service-discovery]
---

# ExternalDNS

**Purpose:** For platform engineers, operators, documents the external-dns service in openCenter-gitops-base.

`external-dns` synchronizes exposed Kubernetes Services, Ingresses, and Gateway API resources with external DNS providers, automating DNS record management.

## What This Repo Deploys

- `Namespace/external-dns`
- HelmRepository `external-dns` pointing to `https://kubernetes-sigs.github.io/external-dns/`
- HelmRelease `external-dns` deploying chart version `1.20.0` into `external-dns`
- Base Helm values via `external-dns-values-base` Secret

## When to Use It

- You need automatic DNS record creation when Services or Ingresses are exposed.
- You want DNS records to stay in sync with your Kubernetes resources lifecycle.
- You use a supported DNS provider (Route 53, Cloudflare, Azure DNS, Google Cloud DNS, etc.).
- You want to manage DNS records declaratively through Kubernetes annotations.

## Example

```yaml
# Cluster overlay override for provider configuration
apiVersion: v1
kind: Secret
metadata:
  name: external-dns-values-override
  namespace: external-dns
type: Opaque
stringData:
  override.yaml: |
    provider:
      name: cloudflare
    env:
      - name: CF_API_TOKEN
        valueFrom:
          secretKeyRef:
            name: cloudflare-api-token
            key: token
    domainFilters:
      - example.com
    txtOwnerId: poc-cluster
```

## Configuration Surfaces

- Service path: `applications/base/services/external-dns/`
- Namespace: `external-dns`
- Deployment method: Helm chart via Flux HelmRelease
- Base values: `helm-values/values-1.20.0.yaml`
- Override mechanism: optional `external-dns-values-override` Secret in `external-dns`

## Upstream References

- [ExternalDNS GitHub repository](https://github.com/kubernetes-sigs/external-dns)
- [ExternalDNS Helm chart](https://kubernetes-sigs.github.io/external-dns/)
- [ExternalDNS documentation](https://kubernetes-sigs.github.io/external-dns/latest/)
