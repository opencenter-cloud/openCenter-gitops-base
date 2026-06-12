---
id: service-cilium
title: "cilium"
sidebar_label: cilium
description: Reference for the Cilium CNI service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [cilium, cni, networking, ebpf]
---

# Cilium

**Purpose:** For platform engineers, operators, documents the Cilium CNI service in openCenter-gitops-base.

`Cilium` provides eBPF-based networking, observability, and security for Kubernetes clusters. In this repository it is deployed as a Flux-managed Helm release in the `kube-system` namespace.

## What This Repo Deploys

- A `Namespace/kube-system` (pre-existing)
- A `HelmRepository/cilium`
- A `HelmRelease/cilium`
- Base chart values from the service `helm-values/` directory
- An optional override Secret named `cilium-values-override`

## When to Use It

- You need high-performance eBPF-based networking with low overhead.
- You want kube-proxy replacement for improved service routing.
- You need advanced observability via Hubble.
- You want transparent encryption (WireGuard or IPsec) between nodes.
- You need Cluster Mesh for multi-cluster connectivity.

## Key Integration Points

- When using Cilium as kube-proxy replacement, kubeadm must be initialized with `--skip-phases=addon/kube-proxy`.
- Hubble integrates with Grafana/Prometheus for network observability.
- Cilium network policies supplement or replace Kubernetes NetworkPolicy resources.
- Gateway API and service mesh features can be enabled via Helm values.

## Configuration Surfaces

- Service path: `applications/base/services/cilium/`
- Namespace: `kube-system`
- Flux object: `HelmRelease/cilium`
- Base values Secret: `cilium-values-base`
- Override values Secret: `cilium-values-override`
- Source: Cilium Helm repository (`https://helm.cilium.io/`)

## Related Docs

- [Gateway API Reference](gateway-api.md)

## Upstream References

- [Cilium documentation](https://docs.cilium.io/en/stable/)
- [Cilium Helm chart reference](https://docs.cilium.io/en/stable/helm-reference/)
- [Cilium kubeadm installation](https://docs.cilium.io/en/stable/installation/k8s-install-kubeadm/)
- [Hubble observability](https://docs.cilium.io/en/stable/observability/hubble/)
