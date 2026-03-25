---
id: service-istio
title: "istio"
sidebar_label: istio
description: Reference for the Istio service mesh deployment in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, service owners"
tags: [istio, service-mesh, traffic-management]
---

# Istio

`istio` deploys a service mesh control plane in three parts: base CRDs, `istiod`, and an ingress gateway.

## What This Repo Deploys

- `Namespace/istio-system`
- `HelmRelease/istio-base`
- `HelmRelease/istiod`
- `HelmRelease/istio-gateway`
- separate base and override Secrets for each stage

## When to Use It

- You need mTLS, advanced traffic policy, or service-mesh telemetry.
- You need ingress and east-west traffic controls managed together.

## Example

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: app
spec:
  hosts:
    - app.example.com
  gateways:
    - istio-system/istio-ingressgateway
```

## Configuration Surfaces

- Service path: `applications/base/services/istio/`
- Namespace: `istio-system`
- Flux objects: `istio-base`, `istiod`, `istio-gateway`
- Source: Istio Helm repository declared under `sources/`

## Upstream References

- [Istio docs](https://istio.io/latest/docs/)
- [Istio traffic management](https://istio.io/latest/docs/concepts/traffic-management/)
- [Istio security and mTLS](https://istio.io/latest/docs/concepts/security/)
