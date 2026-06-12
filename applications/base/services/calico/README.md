# Calico (Tigera Operator)

Calico provides networking and network policy for Kubernetes clusters, deployed via the Tigera Operator.

## Components

| Resource | Purpose |
|----------|---------|
| `namespace.yaml` | Creates the `tigera-operator` namespace |
| `source.yaml` | HelmRepository pointing to `https://docs.tigera.io/calico/charts` |
| `helmrelease-crds.yaml` | Deploys CRDs (`crd.projectcalico.org.v1` chart) |
| `helmrelease.yaml` | Deploys the `tigera-operator` chart (depends on CRDs) |
| `helm-values/values-v3.32.0.yaml` | Base Helm values |

## Version

- Chart: `v3.32.0`
- Source: [Project Calico Helm Charts](https://docs.tigera.io/calico/charts)

## Overrides

Cluster-specific overrides are supplied via the `calico-values-override` Secret (optional).
The IaC module at `iac/cni/calico/` generates overlay values for interface detection, IP pools, and encapsulation settings.
