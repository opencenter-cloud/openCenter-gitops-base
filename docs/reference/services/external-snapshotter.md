---
id: service-external-snapshotter
title: "external-snapshotter"
sidebar_label: external-snapshotter
description: Reference for the external-snapshotter service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [snapshot, csi, storage]
---

# External Snapshotter

`external-snapshotter` installs the CSI snapshot controller and CRDs behind the Kubernetes `VolumeSnapshot` APIs.

## What This Repo Deploys

- `Namespace/external-snapshotter`
- upstream CRDs from the `external-snapshotter` repository
- upstream snapshot-controller manifests pinned to `v8.2.1`

## When to Use It

- Your CSI drivers or backup tools need `VolumeSnapshot` support.
- You want Velero or application workflows to use CSI-native snapshots.

## Example

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: app-data-snapshot
spec:
  volumeSnapshotClassName: csi-snapclass
  source:
    persistentVolumeClaimName: app-data
```

## Configuration Surfaces

- Service path: `applications/base/services/external-snapshotter/`
- Namespace: `external-snapshotter`
- Deployment method: remote manifests from the upstream project

## Upstream References

- [CSI snapshot documentation](https://kubernetes-csi.github.io/docs/snapshot-restore-feature.html)
- [Snapshot controller deployment docs](https://kubernetes-csi.github.io/docs/snapshot-controller.html)
- [external-snapshotter repository](https://github.com/kubernetes-csi/external-snapshotter)
