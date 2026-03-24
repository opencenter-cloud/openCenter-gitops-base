---
id: velero-config-guide
title: "Velero Configuration Guide"
sidebar_label: Velero
description: How to configure Velero in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [velero, backup, disaster-recovery, kubernetes]
---

# Velero Configuration Guide

Use this guide when a cluster repo needs to add the storage backend, snapshot behavior, or restore strategy for the Velero deployment shipped by the base repo.

## What the Base Deploys

The base service deploys:

- `Namespace/velero`
- `HelmRelease/velero`
- base values from the service `helm-values/` directory
- optional `Secret/velero-values-override`

## Common Cluster-Specific Configuration

Most clusters need to configure:

- `BackupStorageLocation`
- CSI snapshot behavior and supporting snapshot classes
- provider credentials
- namespace schedules and backup retention
- node-agent or filesystem backup policy, if used

## Override Values Pattern

Example `override.yaml`:

```yaml
configuration:
  features: EnableCSI

credentials:
  useSecret: true
  existingSecret: cloud-credentials

backupsEnabled: true
snapshotsEnabled: true
```

## Operational Guidance

- Decide whether the platform relies primarily on CSI snapshots or file-level backups.
- Treat backup credentials and provider config as cluster-local inputs.
- Test restores regularly; backup success alone is not enough.

## Verification

```bash
kubectl get helmrelease -n velero velero
kubectl get pods -n velero
kubectl get backupstoragelocation,backup,restore -n velero
velero backup get
```

Healthy signs:

- `HelmRelease/velero` is `Ready=True`
- backup storage location is `Available`
- backups complete successfully

## Common Failure Modes

Backup storage unavailable:
- verify provider credentials and bucket/container reachability

Volume snapshots fail:
- verify CSI driver snapshot support and snapshot classes

Restores partially succeed:
- inspect restore logs and ordering of dependent resources

## Related Docs

- [Velero Service Reference](../../reference/services/velero.md)
- [Velero with Swift and vSphere CSI](velero-with-swift-vsphere-csi.md)
