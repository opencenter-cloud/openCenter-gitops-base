---
id: service-gateway-api
title: "gateway-api"
sidebar_label: gateway-api
description: Reference for the Envoy Gateway based gateway-api service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, application teams"
tags: [gateway-api, ingress, envoy]
---

# Gateway API

The `gateway-api` service deploys Envoy Gateway as the implementation for Kubernetes Gateway API resources.

## What This Repo Deploys

- `Namespace/envoy-gateway-system`
- `HelmRelease/envoy-gateway-api`
- Base values Secret: `envoy-gateway-api-values-base`
- Optional override Secret: `envoy-gateway-api-values-override`

## When to Use It

- You want Gateway API rather than legacy ingress-only routing.
- You need shared edge infrastructure with delegated route ownership.

## Key Integration Points

- `cert-manager` usually provides TLS automation.
- MetalLB or a cloud load balancer provides external IPs.

## Example

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app
spec:
  parentRefs:
    - name: public
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: app
          port: 80
```

## Configuration Surfaces

- Service path: `applications/base/services/gateway-api/`
- Namespace: `envoy-gateway-system`
- Flux object: `HelmRelease/envoy-gateway-api`
- Source: `oci://docker.io/envoyproxy`

## Upstream References

- [Gateway API project docs](https://gateway-api.sigs.k8s.io/)
- [Envoy Gateway docs](https://gateway.envoyproxy.io/docs/)
- [Envoy Gateway Helm chart](https://artifacthub.io/packages/helm/envoyproxy/gateway-helm)
