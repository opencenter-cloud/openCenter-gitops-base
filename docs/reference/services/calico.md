---
id: service-calico
title: "calico"
sidebar_label: calico
description: Reference for the Calico (Tigera Operator) CNI service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [calico, cni, networking, tigera-operator]
---

# Calico (Tigera Operator)

**Purpose:** For platform engineers, operators, documents the Calico CNI service in openCenter-gitops-base.

`Calico` provides networking and network policy for Kubernetes clusters, deployed via the Tigera Operator. In this repository it is deployed as Flux-managed Helm releases in the `tigera-operator` namespace.

## What This Repo Deploys

- A `Namespace/tigera-operator`
- A `HelmRepository/projectcalico`
- A `HelmRelease/calico-crds` (CRD chart deployed first)
- A `HelmRelease/calico` (Tigera Operator, depends on CRDs)
- Base chart values from the service `helm-values/` directory
- An optional override Secret named `calico-values-override`

## When to Use It

- You need a production-grade CNI with built-in network policy enforcement.
- You require BGP peering, VXLAN/IPIP encapsulation, or WireGuard encryption.
- You want Windows node networking support.
- You need per-namespace or per-pod network policy control.

## Key Integration Points

- The IaC module at `iac/cni/calico/` generates cluster-specific overlay values (interface detection, IP pools, encapsulation).
- Network policies (`applications/policies/network-policies/`) rely on Calico's policy engine.
- MetalLB or other load balancers may interact with Calico's BGP configuration.

## Configuration Surfaces

- Service path: `applications/base/services/calico/`
- Namespace: `tigera-operator`
- Flux objects: `HelmRelease/calico-crds`, `HelmRelease/calico`
- Base values Secret: `calico-values-base`
- Override values Secret: `calico-values-override`
- Source: Project Calico Helm repository (`https://docs.tigera.io/calico/charts`)

## Related Docs

- [IaC CNI Calico module](../../../iac/cni/calico/README.md)

## Upstream References

- [Calico documentation](https://docs.tigera.io/calico/latest/about/)
- [Tigera Operator Helm chart](https://docs.tigera.io/calico/latest/getting-started/kubernetes/helm)
- [Calico network policy reference](https://docs.tigera.io/calico/latest/reference/resources/networkpolicy)
