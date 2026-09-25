# Cilium

Cilium provides eBPF-based networking, observability, and security for Kubernetes clusters.

## Components

| Resource | Purpose |
|----------|---------|
| `namespace.yaml` | Ensures `kube-system` namespace exists |
| `source.yaml` | HelmRepository pointing to `https://helm.cilium.io/` |
| `helmrelease.yaml` | Deploys the `cilium` chart |
| `helm-values/values-1.20.2.yaml` | Base Helm values |

## Version

- Chart: `1.20.2`
- Source: [Cilium Helm Charts](https://helm.cilium.io/)

## Overrides

Cluster-specific overrides are supplied via the `cilium-values-override` Secret (optional).

## Notes

- Deployed to `kube-system` namespace as recommended for kubeadm clusters.
- If using Cilium as kube-proxy replacement, set `kubeProxyReplacement: true` in the override values.
- Reference: https://docs.cilium.io/en/stable/installation/k8s-install-kubeadm/

## Repository implementation

- Source path: `applications/base/services/cilium/`.
- Flux entrypoint: `kustomization.yaml`; it renders the `kube-system` namespace reference, HelmRepository, HelmRelease, and `cilium-values-base` Secret.
- Base values: `helm-values/values-1.20.2.yaml`.
- Cluster-specific values are supplied through the optional `cilium-values-override` Secret.

The active base values set `ipam.operator.clusterPoolIPv4PodCIDRList` to `10.244.0.0/16`. Treat this as a real pod-CIDR default and replace it through the override Secret when it does not match the cluster network.

## Validation and limitations

Run `kustomize build applications/base/services/cilium/` to validate the local manifests. The base selects the `10.244.0.0/16` pod CIDR above but does not select a cluster interface, service CIDR, or kube-proxy replacement mode; configure or replace those in the override Secret. Rendering does not install Cilium or verify kernel, node, or API-server prerequisites.
