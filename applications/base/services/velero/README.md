# Velero – Base Configuration

This directory contains the **base manifests** for deploying [Velero](https://velero.io/), an open-source tool for **backup, restore, and disaster recovery** of Kubernetes clusters and persistent volumes.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/velero.md).

**About Velero:**

- Provides **backup and restore** capabilities for Kubernetes resources, namespaces, and persistent volumes.  
- Supports **scheduled backups**, **on-demand restores**, and **disaster recovery** across clusters or environments.  
- Integrates with multiple storage backends, including **S3-compatible object storage**.
- Uses **BackupStorageLocation** and **VolumeSnapshotLocation** custom resources to manage backup targets and configurations.  
- Works seamlessly with **CSI snapshotters**(such as External Snapshotter) for volume-level backups.  
- Enables **migration of workloads** between clusters by restoring backups into new environments.  
- Supports encryption, retention policies, and incremental backups for efficient and secure data protection.  
- Commonly used to safeguard production workloads and ensure recoverability in hybrid or multi-cluster Kubernetes deployments.  
- Simplifies cluster recovery workflows and enhances operational resilience.  

## Repository implementation

- Source path: `applications/base/services/velero/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `velero` and reads `velero-values-base` plus the optional `velero-values-override` Secret.
- Base values: `helm-values/values-12.2.0.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/velero/` to validate the local manifests. The base does not configure an object-store credential, `BackupStorageLocation`, schedules, or a volume-snapshot provider. Backups are not available until those cluster-specific resources and permissions are configured.
