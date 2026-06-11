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
