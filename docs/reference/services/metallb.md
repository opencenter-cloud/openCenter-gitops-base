---
id: service-metallb
title: "metallb"
sidebar_label: metallb
description: Reference for the MetalLB service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, network engineers"
tags: [metallb, networking, loadbalancer]
---

# MetalLB

`metallb` provides `LoadBalancer` service support on clusters that do not have a native cloud load balancer. In this repository it is deployed as a Helm release in `metallb-system`.

## What This Repo Deploys

- `Namespace/metallb-system` with privileged Pod Security labels
- `HelmRelease/metallb`
- Base values Secret: `metallb-values-base`
- Optional override Secret: `metallb-values-override`

## When to Use It

- You run bare-metal or private cloud clusters without a managed load balancer.
- You want stable IPs for ingress controllers, gateways, or other edge services.
- You want Layer 2 or BGP-based service advertisement managed inside Kubernetes.

## Key Integration Points

- Gateway API, ingress controllers, and service meshes often depend on MetalLB-provided IPs.
- IP pools and BGP peers are usually cluster-local manifests, not base values.

## Example

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: public-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.0.2.100-192.0.2.120
```

## Configuration Surfaces

- Service path: `applications/base/services/metallb/`
- Namespace: `metallb-system`
- Flux object: `HelmRelease/metallb`
- Base values Secret: `metallb-values-base`
- Override values Secret: `metallb-values-override`

## Related Docs

- [MetalLB Configuration Guide](../../how-to/services/metallb.md)

## Upstream References

- [MetalLB docs](https://metallb.universe.tf/)
- [MetalLB configuration guide](https://metallb.universe.tf/configuration/)
- [MetalLB Helm chart](https://artifacthub.io/packages/helm/metallb/metallb)
