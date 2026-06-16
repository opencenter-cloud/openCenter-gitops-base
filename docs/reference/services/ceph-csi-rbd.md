---
id: service-ceph-csi-rbd
title: "ceph-csi-rbd"
sidebar_label: ceph-csi-rbd
description: Reference for the ceph-csi-rbd service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [storage, csi, ceph, rbd, block-storage]
---

# Ceph CSI RBD

**Purpose:** For platform engineers, operators, documents the ceph-csi-rbd service in openCenter-gitops-base.

`ceph-csi-rbd` installs the Ceph CSI RBD driver providing dynamic provisioning of RADOS Block Device volumes for Kubernetes workloads.

## What This Repo Deploys

- `Namespace/ceph-csi` (via parent `ceph-csi/namespace/` directory)
- HelmRepository `ceph-csi` pointing to `https://ceph.github.io/csi-charts/`
- HelmRelease `ceph-csi-rbd` deploying chart version `3.17.0` into `ceph-csi`
- Base Helm values via `ceph-csi-rbd-values-base` Secret

## When to Use It

- Your cluster uses Ceph for persistent storage and needs RBD (block) volumes.
- You want dynamic provisioning of PersistentVolumes backed by Ceph RBD.
- You need CSI snapshot, clone, or volume expansion support with Ceph.

## Example

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-rbd
provisioner: rbd.csi.ceph.com
parameters:
  clusterID: "<ceph-cluster-id>"
  pool: kubernetes
  csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
  csi.storage.k8s.io/provisioner-secret-namespace: ceph-csi
reclaimPolicy: Delete
allowVolumeExpansion: true
```

## Configuration Surfaces

- Service path: `applications/base/services/ceph-csi/ceph-csi-rbd/`
- Namespace: `ceph-csi`
- Deployment method: Helm chart via Flux HelmRelease
- Base values: `helm-values/values-3.17.0.yaml`
- Override mechanism: optional `ceph-csi-rbd-values-override` Secret in `ceph-csi`

## Upstream References

- [Ceph CSI documentation](https://github.com/ceph/ceph-csi/blob/devel/docs/deploy-rbd.md)
- [Ceph CSI Helm charts](https://ceph.github.io/csi-charts/)
- [Ceph CSI GitHub repository](https://github.com/ceph/ceph-csi)
