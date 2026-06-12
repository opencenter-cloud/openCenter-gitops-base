# Cilium

Cilium provides eBPF-based networking, observability, and security for Kubernetes clusters.

## Components

| Resource | Purpose |
|----------|---------|
| `namespace.yaml` | Ensures `kube-system` namespace exists |
| `source.yaml` | HelmRepository pointing to `https://helm.cilium.io/` |
| `helmrelease.yaml` | Deploys the `cilium` chart |
| `helm-values/values-v1.19.4.yaml` | Base Helm values |

## Version

- Chart: `1.19.4`
- Source: [Cilium Helm Charts](https://helm.cilium.io/)

## Overrides

Cluster-specific overrides are supplied via the `cilium-values-override` Secret (optional).

## Notes

- Deployed to `kube-system` namespace as recommended for kubeadm clusters.
- If using Cilium as kube-proxy replacement, set `kubeProxyReplacement: true` in the override values.
- Reference: https://docs.cilium.io/en/stable/installation/k8s-install-kubeadm/
