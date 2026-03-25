# External-Snapshotter – Base Configuration

This directory contains the **base manifests** for deploying the [External Snapshotter](https://kubernetes-csi.github.io/docs/snapshot-controller.html), a Kubernetes CSI component responsible for managing volume snapshots.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/external-snapshotter.md).

**About External-Snapshotter:**

- Provides Kubernetes-native APIs (`VolumeSnapshot`, `VolumeSnapshotContent`, and `VolumeSnapshotClass`) for managing persistent volume snapshots.  
- Works with CSI drivers that support snapshot capabilities to create, restore, and delete snapshots.  
- Consists of the **snapshot-controller**, **CRDs**, and **webhook** components.  
- Enables backup, restore, and cloning workflows for persistent volumes.  
- Decouples snapshot lifecycle management from storage vendors, offering a consistent interface across environments.  
- Commonly used in backup automation, disaster recovery, and application data protection scenarios.  
- Simplifies volume snapshot management and improves data resilience in Kubernetes clusters.  
