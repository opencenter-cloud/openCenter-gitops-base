---
id: service-vsphere-csi
title: "vsphere-csi"
sidebar_label: vsphere-csi
description: Reference for the vSphere CSI service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, virtualization teams"
tags: [vsphere, csi, storage]
---

# vSphere CSI

`vsphere-csi` provides Kubernetes persistent storage integration for VMware vSphere. In this repository it is installed as a Helm release in `vmware-system-csi`.

## What This Repo Deploys

- `Namespace/vmware-system-csi` with privileged Pod Security labels
- `HelmRelease/vsphere-csi`
- Base values Secret: `vsphere-csi-values-base`
- Optional override Secret: `vsphere-csi-values-override`

## When to Use It

- You run Kubernetes on vSphere and want CSI-native persistent storage.
- You need snapshots, expansion, and cloning on VMware-backed volumes.
- You need topology-aware provisioning aligned to vSphere failure domains.

## Key Integration Points

- vSphere CPI should already be installed so nodes have ProviderIDs.
- `external-snapshotter` and snapshot classes are required for Velero CSI workflows.
- Cluster-local secrets provide vCenter connectivity details.

## Example

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: vsphere-gold
provisioner: csi.vsphere.vmware.com
allowVolumeExpansion: true
```

## Configuration Surfaces

- Service path: `applications/base/services/vsphere-csi/`
- Namespace: `vmware-system-csi`
- Flux object: `HelmRelease/vsphere-csi`
- Base values Secret: `vsphere-csi-values-base`
- Override values Secret: `vsphere-csi-values-override`

## Related Docs

- [vSphere CSI Configuration Guide](../../how-to/services/vsphere-csi.md)
- [Velero with Swift and vSphere CSI](../../how-to/services/velero-with-swift-vsphere-csi.md)

## Upstream References

- [vSphere CSI docs](https://vsphere-csi-driver.sigs.k8s.io/)
- [Topology feature docs](https://vsphere-csi-driver.sigs.k8s.io/features/topology.html)
- [Helm chart repository](https://github.com/vsphere-tmm/helm-charts)
