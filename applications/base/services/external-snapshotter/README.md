# External-Snapshotter – Base Configuration

This directory contains the **base manifests** for deploying the [External Snapshotter](https://kubernetes-csi.github.io/docs/snapshot-controller.html), a Kubernetes CSI component responsible for managing volume snapshots.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/external-snapshotter.md).

**About External-Snapshotter:**

- Provides Kubernetes-native APIs (`VolumeSnapshot`, `VolumeSnapshotContent`, and `VolumeSnapshotClass`) for managing persistent volume snapshots.  
- Works with CSI drivers that support snapshot capabilities to create, restore, and delete snapshots.  
- Consists of the **snapshot-controller** and **CRDs**. This base does not deploy the optional webhook component.
- Enables backup, restore, and cloning workflows for persistent volumes.  
- Decouples snapshot lifecycle management from storage vendors, offering a consistent interface across environments.  
- Commonly used in backup automation, disaster recovery, and application data protection scenarios.  
- Simplifies volume snapshot management and improves data resilience in Kubernetes clusters.  

## Repository implementation

- Source path: `applications/base/services/external-snapshotter/`.
- Kustomize entrypoint: `kustomization.yaml`; it fetches the snapshot CRDs and snapshot-controller manifests as remote Kustomize bases pinned to `v8.2.1`. Only the namespace manifest is local; no webhook resource is included.
- No Helm values or provider credentials are included. CSI drivers consume the snapshot APIs after this controller is installed.

## Validation and limitations

Run `kustomize build applications/base/services/external-snapshotter/` to validate the local manifests. The build requires access to the pinned remote bases. A CSI driver that supports snapshots is still required, and this base does not create `VolumeSnapshotClass` objects, webhook resources, or backup schedules for a particular storage backend.
