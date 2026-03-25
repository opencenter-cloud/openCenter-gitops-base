# OpenStack Cinder CSI Driver – Base Configuration

This directory contains the **base manifests** for deploying the [OpenStack Cinder CSI Driver](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/cinder-csi-plugin/using-cinder-csi-plugin.md), which integrates Kubernetes with OpenStack's block storage service(Cinder) to provide dynamic volume provisioning.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/openstack-csi.md).

**About OpenStack Cinder CSI Driver:**

- Enables Kubernetes workloads to use **OpenStack Cinder volumes** as persistent storage.  
- Supports **dynamic provisioning**, **expansion**, **snapshotting**, and **cloning** of volumes.  
- Integrates with the **External Snapshotter** for snapshot and restore operations.  
- Works in conjunction with the **OpenStack Cloud Controller Manager (CCM)** for seamless resource coordination.  
- Securely manages volume credentials through **Kubernetes Secrets** and **OpenStack credentials** configuration.  
- Commonly used in OpenStack-based Kubernetes clusters to provide scalable, high-performance, and fault-tolerant persistent storage.  
