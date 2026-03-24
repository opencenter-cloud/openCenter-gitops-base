---
id: velero-swift-vsphere-csi-config-guide
title: "Velero Backup with Swift and vSphere CSI"
sidebar_label: Velero Swift/vSphere
description: Practical configuration notes for running Velero with OpenStack Swift object storage and vSphere CSI snapshots.
doc_type: how-to
audience: "platform engineers, operators"
tags: [velero, backup, swift, vsphere, csi, openstack]
---

# Velero Backup with Swift and vSphere CSI

This guide documents one concrete platform pattern: using Velero with the OpenStack plugin for Swift object storage and CSI snapshots from the vSphere CSI driver.

## When This Pattern Fits

Use this pattern when:

- backup metadata and manifests should live in Swift
- workload volumes are backed by vSphere CSI
- CSI snapshots are preferred over filesystem backups

## Key Configuration Points

- `BackupStorageLocation` uses the OpenStack provider plugin
- CSI is enabled through `configuration.features: EnableCSI`
- `defaultVolumesToFsBackup` remains `false`
- `VolumeSnapshotClass` must exist for the vSphere CSI driver
- the `cloud-credentials` Secret must expose the required `OS_*` environment variables

## Example Fragments

```yaml
backupStorageLocations:
  - name: default
    provider: community.openstack.org/openstack
    bucket: k8s-dr-velero
```

```yaml
configuration:
  features: EnableCSI
  defaultSnapshotMoveData: false
  defaultVolumesToFsBackup: false
  volumeSnapshotLocation: []
```

## Important Constraints

- Kopia filesystem backup support is not the primary path in this Swift-based pattern.
- Swift temp URL settings must be consistent between the object storage container and the Velero credentials.
- vSphere CSI snapshot support must already be working independently of Velero.

## Verification

```bash
kubectl get backupstoragelocation -n velero
kubectl get volumesnapshotclass
kubectl logs -n velero deploy/velero
velero backup get
```

## Common Failure Modes

`Missing input for argument [auth_url]`:
- required `OS_*` variables are not present in `cloud-credentials`

`Temp URL invalid` or `401`:
- the configured temp URL key does not match the Swift container setting

Snapshot-related backups fail:
- verify the `VolumeSnapshotClass` label and vSphere CSI snapshot health
