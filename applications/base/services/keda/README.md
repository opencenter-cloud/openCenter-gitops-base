# KEDA

Base Flux manifests for deploying KEDA 2.21.0 in the `keda` namespace from the official KEDA Helm repository.

The base values enable CRD installation and leave namespace watching and secret access unrestricted so applications can use KEDA trigger secrets in their own namespaces. Cluster-specific Helm values can be supplied through the optional `keda-values-override` Secret.
