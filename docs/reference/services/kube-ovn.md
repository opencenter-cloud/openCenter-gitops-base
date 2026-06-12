---
id: service-kube-ovn
title: "kube-ovn"
sidebar_label: kube-ovn
description: Reference for the Kube-OVN CNI service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [kube-ovn, cni, networking, ovn, ovs]
---

# Kube-OVN

**Purpose:** For platform engineers, operators, documents the Kube-OVN CNI service in openCenter-gitops-base.

`Kube-OVN` provides OVN/OVS-based advanced container networking with support for VPCs, subnets, security groups, QoS, and multi-cluster interconnection. In this repository it is deployed as a Flux-managed Helm release in the `kube-system` namespace.

## What This Repo Deploys

- A `Namespace/kube-system` (pre-existing)
- A `HelmRepository/kubeovn`
- A `HelmRelease/kube-ovn` (includes CRDs via `crds: CreateReplace`)
- Base chart values from the service `helm-values/` directory
- An optional override Secret named `kube-ovn-values-override`

## When to Use It

- You need multi-tenant VPC isolation at the network layer.
- You require OVN-based subnet management with fine-grained IP address control.
- You want security groups, QoS policies, and EIP/SNAT capabilities.
- You need multi-cluster interconnection via OVN-IC.
- You are running KubeVirt and need fixed VM IP addresses with live migration support.

## Key Integration Points

- Control-plane nodes must be labeled with `kube-ovn/role=master` before deployment.
- `MASTER_NODES` in the override values must contain the internal IPs of master nodes.
- Kube-OVN CRDs (Subnet, VPC, IP, Vlan, etc.) enable declarative network management.
- The `kubectl-ko` plugin provides network diagnostics.

## Configuration Surfaces

- Service path: `applications/base/services/kube-ovn/`
- Namespace: `kube-system`
- Flux object: `HelmRelease/kube-ovn`
- Base values Secret: `kube-ovn-values-base`
- Override values Secret: `kube-ovn-values-override`
- Source: Kube-OVN Helm repository (`https://kubeovn.github.io/kube-ovn/`)

## Upstream References

- [Kube-OVN documentation](https://kubeovn.github.io/docs/stable/en/)
- [Kube-OVN Helm chart](https://kubeovn.github.io/kube-ovn/)
- [Installation guide](https://kubeovn.github.io/docs/stable/en/start/one-step-install/)
- [Architecture reference](https://kubeovn.github.io/docs/stable/en/reference/architecture/)
