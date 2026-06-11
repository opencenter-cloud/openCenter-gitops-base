---
id: service-ceph-csi
title: "ceph-csi"
sidebar_label: ceph-csi
description: Reference for the Ceph CSI RBD service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, storage teams"
tags: [ceph, rbd, csi, storage]
---

# Ceph CSI

**Purpose:** For platform engineers, storage teams, documents the Ceph CSI RBD service in openCenter-gitops-base.

`ceph-csi` deploys the Ceph RBD CSI driver so block volumes backed by a Ceph cluster can be dynamically provisioned in Kubernetes.

## What This Repo Deploys

- `Namespace/ceph-csi`
- `HelmRelease/ceph-csi-rbd`
- Base values Secret: `ceph-csi-rbd-values-base`
- Optional override Secret: `ceph-csi-rbd-values-override`

## When to Use It

- Persistent block storage backed by an external Ceph cluster is needed.

## Example

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-rbd
provisioner: rbd.csi.ceph.com
parameters:
  clusterID: "<cluster-id>"
  pool: "kubernetes"
  csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
  csi.storage.k8s.io/provisioner-secret-namespace: ceph-csi
reclaimPolicy: Delete
allowVolumeExpansion: true
```

## Configuration Surfaces

- Service path: `applications/base/services/ceph-csi/`
- Namespace: `ceph-csi`
- Flux object: `HelmRelease/ceph-csi-rbd`
- Source: `https://ceph.github.io/csi-charts/`

## Upstream References

- [Ceph CSI GitHub](https://github.com/ceph/ceph-csi)
- [RBD deployment docs](https://github.com/ceph/ceph-csi/blob/devel/docs/rbd/deploy.md)
- [CephFS deployment docs](https://github.com/ceph/ceph-csi/blob/devel/docs/cephfs/deploy.md)
