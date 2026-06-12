# Kube-OVN

Kube-OVN provides OVN/OVS-based advanced container networking with support for VPC, subnets, security groups, QoS, and multi-cluster interconnection.

## Components

| Resource | Purpose |
|----------|---------|
| `namespace.yaml` | Ensures `kube-system` namespace exists |
| `source.yaml` | HelmRepository pointing to `https://kubeovn.github.io/kube-ovn/` |
| `helmrelease.yaml` | Deploys the `kube-ovn` chart with CRDs |
| `helm-values/values-v1.16.2.yaml` | Base Helm values |

## Version

- Chart: `v1.16.2`
- Source: [Kube-OVN Helm Charts](https://kubeovn.github.io/kube-ovn/)

## Prerequisites

- Nodes with `kube-ovn/role=master` label on control-plane nodes
- Reference: https://kubeovn.github.io/docs/stable/en/start/one-step-install/

## Overrides

Cluster-specific overrides (MASTER_NODES IPs, IFACE, CIDRs) are supplied via the `kube-ovn-values-override` Secret (optional).
