---
id: vsphere-csi-config-guide
title: "vSphere CSI Driver Configuration"
sidebar_label: vSphere CSI
description: How to configure the vSphere CSI driver in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [vsphere, csi, storage, snapshots, kubernetes]
---

# vSphere CSI Driver Configuration

Use this guide when a cluster repo needs to provide vCenter credentials, storage policies, snapshot support, or topology settings for the base vSphere CSI deployment.

## What the Base Deploys

The base service deploys:

- `Namespace/vmware-system-csi`
- `HelmRelease/vsphere-csi`
- base values from the service `helm-values/` directory
- optional `Secret/vsphere-csi-values-override`

The base does not create the vCenter credential Secrets required by the driver.

## Required Supporting Inputs

Cluster repos normally provide:

- `vsphere-config-secret` with `csi-vsphere.conf`
- CPI configuration and working node `ProviderID`s
- storage classes appropriate for the environment
- snapshot classes if Velero or application workflows need CSI snapshots

## Override Values Pattern

Example `override.yaml`:

```yaml
controller:
  replicaCount: 3
  snapshotter:
    image:
      registry: registry.k8s.io
      repository: sig-storage/csi-snapshotter

snapshot:
  controller:
    enabled: true
```

## Topology Guidance

If the cluster uses vSphere topology awareness:

- tag inventory objects with region / zone labels
- populate matching topology labels in `csi-vsphere.conf`
- ensure workload scheduling and storage classes align to those labels

## Verification

```bash
kubectl get helmrelease -n vmware-system-csi vsphere-csi
kubectl get pods -n vmware-system-csi
kubectl get csidrivers csi.vsphere.vmware.com
kubectl get volumesnapshotclass
```

Healthy signs:

- controller and node Pods are `Running`
- PVC provisioning succeeds
- `VolumeSnapshot` resources reconcile when snapshot support is enabled

## Common Failure Modes

PVC provisioning fails:
- verify vCenter credentials and CPI / ProviderID setup

Snapshots do not work:
- verify snapshot sidecars, snapshot controller, and snapshot class configuration

Topology-aware placement fails:
- verify zone labels in both vSphere and driver config

## Related Docs

- [vSphere CSI Service Reference](../../reference/services/vsphere-csi.md)
- [Velero with Swift and vSphere CSI](velero-with-swift-vsphere-csi.md)
