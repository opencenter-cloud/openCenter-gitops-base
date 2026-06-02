---
id: metallb-config-guide
title: "MetalLB Configuration Guide"
sidebar_label: MetalLB
description: How to configure MetalLB in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [metallb, networking, loadbalancer, kubernetes]
---

# MetalLB Configuration Guide

Use this guide when a cluster repo needs to add IP pools, advertisements, or controller tuning on top of the base MetalLB deployment.

## What the Base Deploys

The base service deploys:

- `Namespace/metallb-system`
- `HelmRelease/metallb`
- base values from the service `helm-values/` directory
- optional `Secret/metallb-values-override`

The base does not define your cluster’s `IPAddressPool`, `L2Advertisement`, or `BGPPeer` resources.

## Common Cluster-Specific Configuration

Most clusters need to define:

- one or more `IPAddressPool` resources
- either `L2Advertisement` or BGP resources
- speaker placement constraints where required
- address sharing policy for ingress / gateway services

## Example Cluster Manifests

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: public-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.0.2.100-192.0.2.120
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: public-pool
  namespace: metallb-system
spec:
  ipAddressPools:
    - public-pool
```

## Override Values Pattern

Use `metallb-values-override` only for controller-level settings such as resources, tolerations, or speaker placement.

## Verification

```bash
kubectl get helmrelease -n metallb-system metallb
kubectl get pods -n metallb-system
kubectl get ipaddresspools,l2advertisements,bgppeers -n metallb-system
kubectl get svc -A --field-selector spec.type=LoadBalancer
```

Healthy signs:

- controller and speaker Pods are `Running`
- assigned `LoadBalancer` services receive IPs from the intended pool

## Common Failure Modes

Services stay pending:
- verify an IP pool exists and is advertised

Announced IPs are not reachable:
- verify Layer 2 adjacency or BGP peering configuration outside the cluster

Speaker Pods do not run on needed nodes:
- verify taints, tolerations, and node selectors

## Related Docs

- [MetalLB Service Reference](../../reference/services/metallb.md)
