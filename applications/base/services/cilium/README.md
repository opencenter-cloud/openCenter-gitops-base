# Cilium – Base Configuration

This directory contains the **base manifests** for deploying [Cilium](https://cilium.io/), an eBPF-based networking, observability, and security solution for Kubernetes clusters.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/cilium.md).

**About Cilium:**

- Provides eBPF-based networking, load balancing, and network policy enforcement for Kubernetes.  
- Supports kube-proxy replacement for improved performance and reduced iptables overhead.  
- Offers transparent encryption (WireGuard/IPsec) for pod-to-pod and node-to-node communication.  
- Includes Hubble for deep network observability with flow visibility and service maps.  
- Implements Kubernetes NetworkPolicy and extended CiliumNetworkPolicy for L3/L4/L7 security.  
- Supports Cluster Mesh for multi-cluster connectivity and service discovery.  
- Deployed to `kube-system` namespace as recommended for kubeadm clusters (no separate namespace resource needed).  
- Cluster-specific overrides are supplied via the `cilium-values-override` Secret (optional).  
