# Ceph CSI RBD – Base Configuration

This directory contains the **base manifests** for deploying [Ceph CSI RBD](https://github.com/ceph/ceph-csi), a CSI driver providing RADOS Block Device storage to Kubernetes workloads.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../../docs/reference/services/ceph-csi-rbd.md).

**About Ceph CSI RBD:**

- Implements the Container Storage Interface (CSI) for Ceph RBD volumes enabling dynamic provisioning.  
- Supports volume snapshots, cloning, expansion, and encryption via CSI primitives.  
- Provides provisioner, attacher, resizer, snapshotter, and driver-registrar sidecars.  
- Supports advanced features including read affinity, volume groups, NVMe-oF transport, and QoS.  
- Production-grade with multi-replica provisioner for high availability.  
- Deployed to `ceph-csi` namespace.  
- Cluster-specific overrides are supplied via the `ceph-csi-rbd-values-override` Secret (optional).  
