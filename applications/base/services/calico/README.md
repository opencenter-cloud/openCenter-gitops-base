# Calico (Tigera Operator)

Calico provides networking and network policy for Kubernetes clusters, deployed via the Tigera Operator.

## Components

| Resource | Purpose |
|----------|---------|
| `namespace.yaml` | Creates the `tigera-operator` namespace |
| `source.yaml` | HelmRepository pointing to `https://docs.tigera.io/calico/charts` |
| `helmrelease-crds.yaml` | Deploys CRDs (`crd.projectcalico.org.v1` chart) |
| `helmrelease.yaml` | Deploys the `tigera-operator` chart (depends on CRDs) |
| `helm-values/values-v3.32.2.yaml` | Base Helm values |

## Version

- Chart: `v3.32.2`
- Source: [Project Calico Helm Charts](https://docs.tigera.io/calico/charts)

## Overrides

Cluster-specific overrides are supplied via the `calico-values-override` Secret (optional).
The IaC module at `iac/cni/calico/` generates overlay values for interface detection, IP pools, and encapsulation settings.

## Repository implementation

- Source path: `applications/base/services/calico/`.
- Flux entrypoint: `kustomization.yaml`; it renders the namespace, HelmRepository, CRD release, operator release, and `calico-values-base` Secret.
- Base values: `helm-values/values-v3.32.2.yaml`.
- The operator HelmRelease depends on `calico-crds`; the optional `calico-values-override` Secret is merged after the base values.

The active base values set the Calico IP pool default to `10.244.0.0/16` with `VXLANCrossSubnet` encapsulation and NAT enabled. Treat this as a real default, not documentation-only example data; replace it through the override Secret or IaC when it does not match the cluster pod CIDR.

## Validation and limitations

Run `kustomize build applications/base/services/calico/` to validate the local manifests. This checks rendered YAML only; Helm chart availability and Flux reconciliation require a cluster or a Flux/Helm controller. The base supplies the `10.244.0.0/16` pod pool and other network defaults above; node interface, credentials, and cluster-specific network settings can be replaced through the IaC module or override Secret.
