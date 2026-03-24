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

## Upstream References

- [Cinder CSI docs](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/cinder-csi-plugin/using-cinder-csi-plugin.md)
- [Cloud Provider OpenStack charts](https://github.com/kubernetes/cloud-provider-openstack/tree/master/charts)
