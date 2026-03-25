---
id: service-velero
title: "velero"
sidebar_label: velero
description: Reference for the Velero service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, disaster-recovery teams"
tags: [velero, backup, disaster-recovery]
---

# Velero

`velero` provides backup, restore, and migration capabilities for Kubernetes resources and persistent volume data. It is the repository’s primary disaster recovery service.

## What This Repo Deploys

- `Namespace/velero` with privileged Pod Security labels
- `HelmRelease/velero`
- Base values Secret: `velero-values-base`
- Optional override Secret: `velero-values-override`

## When to Use It

- You need scheduled or on-demand cluster backups.
- You need restore workflows for namespaces, cluster resources, or persistent volumes.
- You need workload migration or DR testing between clusters.

## Key Integration Points

- CSI drivers and `external-snapshotter` determine how volume snapshots work.
- Backup storage location and credentials are always cluster-specific.
- The Swift/vSphere CSI guide covers one concrete backend pattern used by this platform.

## Example

```bash
velero backup create platform-daily \
  --include-namespaces harbor,keycloak \
  --snapshot-volumes
```

## Configuration Surfaces

- Service path: `applications/base/services/velero/`
- Namespace: `velero`
- Flux object: `HelmRelease/velero`
- Base values Secret: `velero-values-base`
- Override values Secret: `velero-values-override`

## Related Docs

- [Velero Configuration Guide](../../how-to/services/velero.md)
- [Velero with Swift and vSphere CSI](../../how-to/services/velero-with-swift-vsphere-csi.md)

## Upstream References

- [Velero docs](https://velero.io/docs/)
- [Velero Helm chart](https://artifacthub.io/packages/helm/vmware-tanzu/velero)
- [Backup API reference](https://velero.io/docs/main/api-types/backup/)
