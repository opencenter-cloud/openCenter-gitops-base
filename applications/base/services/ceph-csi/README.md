# Ceph CSI – Base Configuration

This directory contains the **base manifests** for deploying
[Ceph CSI](https://github.com/ceph/ceph-csi)
to provide RBD (RADOS Block Device) storage to Kubernetes workloads via the Container Storage Interface.

It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/ceph-csi.md).

## About Ceph CSI

- Implements CSI for Ceph RBD volumes enabling dynamic provisioning, snapshots, cloning, expansion, and encryption.
- Supports RBD and CephFS backed volumes via independent CSI plugins.
- Provides provisioner, attacher, resizer, snapshotter, and driver-registrar sidecars.
- Supports advanced features: read affinity, volume groups, NVMe-oF transport, and QoS.
- Production-grade with multi-replica provisioner for high availability.

## Repository implementation

- Source path: `applications/base/services/ceph-csi/`.
- Kustomize entrypoints: `namespace/kustomization.yaml` creates the namespace and `ceph-csi-rbd/kustomization.yaml` renders the RBD driver resources.
- The RBD chart is sourced from the Ceph CSI Helm repository and uses `ceph-csi-rbd/helm-values/values-3.17.1.yaml`, with optional cluster values from `ceph-csi-rbd-values-override`.
- Cluster-specific Ceph connection data, credentials, pools, and storage classes are supplied by the consuming overlay; this base does not contain them.

## Validation and limitations

Run `kustomize build applications/base/services/ceph-csi/ceph-csi-rbd/` to validate the driver manifests. A working Ceph cluster, monitor endpoints, authentication secret, and compatible RBD configuration are required at runtime. This README covers the RBD driver path; it does not claim that a CephFS driver is enabled by the top-level directory alone.
