---
id: service-cilium
title: "cilium"
sidebar_label: cilium
description: Reference for the cilium service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [networking, cni, ebpf, security, observability]
---

# Cilium

**Purpose:** For platform engineers, operators, documents the cilium service in openCenter-gitops-base.

`cilium` installs the eBPF-based CNI plugin providing networking, network policy enforcement, load balancing, and observability for Kubernetes clusters.

## What This Repo Deploys

- HelmRepository `cilium` pointing to `https://helm.cilium.io/`
- HelmRelease `cilium` deploying chart version `1.19.4` into `kube-system`
- Base Helm values via `cilium-values-base` Secret

## When to Use It

- You need a high-performance CNI with eBPF-based datapath for your Kubernetes cluster.
- You want to replace kube-proxy with Cilium's eBPF implementation.
- You need advanced network policies (L3/L4/L7) beyond standard Kubernetes NetworkPolicy.
- You want built-in network observability via Hubble.
- You require transparent encryption (WireGuard or IPsec) between pods/nodes.

## Example

```yaml
# Cluster overlay override to enable kube-proxy replacement
apiVersion: v1
kind: Secret
metadata:
  name: cilium-values-override
  namespace: kube-system
type: Opaque
stringData:
  override.yaml: |
    kubeProxyReplacement: true
    k8sServiceHost: "api.cluster.local"
    k8sServicePort: "6443"
    hubble:
      enabled: true
      relay:
        enabled: true
      ui:
        enabled: true
```

## Configuration Surfaces

- Service path: `applications/base/services/cilium/`
- Namespace: `kube-system` (built-in, no namespace resource needed)
- Deployment method: Helm chart via Flux HelmRelease
- Base values: `helm-values/values-v1.19.4.yaml`
- Override mechanism: optional `cilium-values-override` Secret in `kube-system`

## Upstream References

- [Cilium documentation](https://docs.cilium.io/en/stable/)
- [Cilium Helm chart values](https://docs.cilium.io/en/stable/helm-reference/)
- [Cilium kubeadm installation guide](https://docs.cilium.io/en/stable/installation/k8s-install-kubeadm/)
- [Hubble observability](https://docs.cilium.io/en/stable/observability/)
- [Cilium GitHub repository](https://github.com/cilium/cilium)
