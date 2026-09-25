---
id: service-openstack-csi
title: "openstack-csi"
sidebar_label: openstack-csi
description: Reference for the OpenStack Cinder CSI service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [openstack, csi, cinder, storage]
---

# OpenStack CSI

**Purpose:** For platform engineers, operators, documents the OpenStack Cinder CSI service in openCenter-gitops-base.

`openstack-csi` deploys the OpenStack Cinder CSI driver so Kubernetes workloads can provision and manage block storage through Cinder.

## What This Repo Deploys

- `Namespace/openstack-csi` with privileged Pod Security labels
- `HelmRelease/openstack-cinder-csi`
- Base values Secret: `openstack-csi-values-base`
- Optional override Secret: `openstack-csi-values-override`

## When to Use It

- The cluster runs on OpenStack and uses Cinder for persistent block storage.

## Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-data
spec:
  storageClassName: cinder-sc
```

## Configuration Surfaces

- Service path: `applications/base/services/openstack-csi/`
- Namespace: `openstack-csi`
- Flux object: `HelmRelease/openstack-cinder-csi`
- Source: Kubernetes cloud-provider-openstack Helm repository
- Chart version: `2.36.5`

> **Important base-value warning:** The committed values enable the chart's delete `StorageClass` and mark it as the cluster default (`storageClass.delete.isDefault: true`); the retain class is enabled but is not default. The values also select the host-mounted cloud configuration path (`secret.enabled: false`, `secret.hostMount: true`). A consumer must verify that `/etc/cloud/cloud.conf` is deliberately provided, then use `openstack-csi-values-override` to select the intended default class or disable the generated classes and to provide the appropriate cloud configuration.

The base path therefore does create an enabled default Cinder `StorageClass`; it does not commit cloud credentials. The consumer must provide valid OpenStack cloud configuration and select the storage class appropriate to its deployment. The example `storageClassName: cinder-sc` is illustrative and must match the class selected by the consumer.

## Upstream References

- [Cinder CSI docs](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/cinder-csi-plugin/using-cinder-csi-plugin.md)
- [Cloud Provider OpenStack charts](https://github.com/kubernetes/cloud-provider-openstack/tree/master/charts)
