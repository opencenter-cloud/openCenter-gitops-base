---
id: service-longhorn
title: "longhorn"
sidebar_label: longhorn
description: Reference for the Longhorn storage service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [longhorn, storage, csi]
---

# Longhorn

`longhorn` provides distributed block storage for Kubernetes clusters. In this repository it is installed as a Helm release in `longhorn-system` together with additional storage classes.

## What This Repo Deploys

- `Namespace/longhorn-system`
- `HelmRelease/longhorn`
- additional storage classes:
  - `longhorn-general`
  - `longhorn-general-multi-attach`
- Base values Secret: `longhorn-values-base`
- Optional `longhorn-values-override`

## When to Use It

- You need persistent volumes on bare metal or general-purpose virtualized clusters.
- You want snapshots, backups, and replicated block storage without a cloud CSI backend.
- You want standard storage classes managed with the platform.

## Key Integration Points

- Application PVCs usually bind to the Longhorn storage classes.
- Backup targets and default settings are cluster-specific.
- Node disk layout and storage networking quality strongly affect Longhorn behavior.

## Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-general
  resources:
    requests:
      storage: 20Gi
```

## Configuration Surfaces

- Service path: `applications/base/services/longhorn/`
- Namespace: `longhorn-system`
- Flux object: `HelmRelease/longhorn`
- Base values Secret: `longhorn-values-base`
- Override values Secret: `longhorn-values-override`

## Related Docs

- [Longhorn Configuration Guide](../../how-to/services/longhorn.md)

## Upstream References

- [Longhorn docs](https://longhorn.io/docs/)
- [Longhorn Helm chart](https://artifacthub.io/packages/helm/longhorn/longhorn)
- [Longhorn concepts](https://longhorn.io/docs/latest/concepts/)
