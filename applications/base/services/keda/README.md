# KEDA

Base Flux manifests for deploying KEDA 2.21.0 in the `keda` namespace from the official KEDA Helm repository.

The base values enable CRD installation and leave namespace watching and secret access unrestricted so applications can use KEDA trigger secrets in their own namespaces. Cluster-specific Helm values can be supplied through the optional `keda-values-override` Secret.

## Repository implementation

- Source path: `applications/base/services/keda/`.
- Flux entrypoint: `kustomization.yaml`; it renders the namespace, HelmRepository, HelmRelease, and `keda-values-base` Secret.
- Base values: `helm-values/values-2.21.0.yaml`.
- The optional `keda-values-override` Secret is merged by the HelmRelease.

## Validation and limitations

Run `kustomize build applications/base/services/keda/` to validate the local manifests. This base installs the KEDA controller and CRDs but does not define application `ScaledObject`, `ScaledJob`, or trigger resources; those belong in a consuming cluster/application overlay. Runtime scaling also depends on the selected metric adapter and workload configuration.
