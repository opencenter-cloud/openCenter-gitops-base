---
id: service-local-path-provisioner
title: "local-path-provisioner"
sidebar_label: local-path-provisioner
description: Reference for the Local Path Provisioner service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [local-path-provisioner, storage, hostpath, persistent-volume]
---

# Local Path Provisioner

`local-path-provisioner` dynamically provisions persistent local storage on Kubernetes nodes using HostPath or Local volumes. It is a lightweight alternative to cloud-based storage provisioners for bare-metal or on-premises clusters.

## What This Repo Deploys

- `Namespace/local-path-storage`
- `GitRepository/local-path-provisioner` (source pinned to upstream release tag)
- `HelmRelease/local-path-provisioner`
- Base values Secret: `local-path-provisioner-values-base`
- Optional override Secret: `local-path-provisioner-values-override`
- `StorageClass/local-path` (created by the Helm chart)

## When to Use It

- You need persistent storage on bare-metal or VM-based clusters without a cloud provider.
- You want a simple, lightweight storage provisioner that uses local node disks.
- You need `ReadWriteOnce` PersistentVolumes backed by node-local directories.

## Key Integration Points

- Works alongside other storage providers (vSphere CSI, Longhorn) — not mutually exclusive.
- The StorageClass can be set as non-default to avoid conflicts with primary storage.
- Useful for workloads that benefit from local disk performance (databases, caches).

## Example

```yaml
# Customer override to change the storage path and set as default
storageClass:
  defaultClass: true
  name: local-path

nodePathMap:
  - node: DEFAULT_PATH_FOR_NON_LISTED_NODES
    paths:
      - /data/local-path-provisioner
```

## Configuration Surfaces

- Service path: `applications/base/services/local-path-provisioner/`
- Namespace: `local-path-storage`
- Flux object: `HelmRelease/local-path-provisioner`
- Source: `GitRepository` pointing to `https://github.com/rancher/local-path-provisioner` (tag `v0.0.36`)
- Chart path within repo: `deploy/chart/local-path-provisioner`

## Important Notes

- This service uses a `GitRepository` source (not `HelmRepository`) because the chart is not published to a public Helm registry.
- The default storage path is `/opt/local-path-provisioner` on each node.
- Data is local to the node — if the node is lost, the data is lost. Not suitable for workloads requiring replication.
- `volumeBindingMode: WaitForFirstConsumer` ensures volumes are provisioned on the node where the pod is scheduled.

## Upstream References

- [Local Path Provisioner GitHub](https://github.com/rancher/local-path-provisioner)
- [Helm chart source](https://github.com/rancher/local-path-provisioner/tree/master/deploy/chart/local-path-provisioner)
- [SUSE Application Collection docs](https://docs.apps.rancher.io/reference-guides/local-path-provisioner/)
