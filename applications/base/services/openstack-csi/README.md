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

## Repository implementation

- Source path: `applications/base/services/openstack-csi/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `openstack-csi` and reads `openstack-csi-values-base` plus the optional `openstack-csi-values-override` Secret.
- Base values: `helm-values/values-2.36.5.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

The active base values enable the chart's StorageClasses. The delete-policy class is marked as the default (`isDefault: true`); the retain-policy class is enabled but not default.

## Validation and limitations

Run `kustomize build applications/base/services/openstack-csi/` to validate the local manifests. The base does not create Cinder credentials or OpenStack projects, but it does create the enabled StorageClasses described above. It depends on a working OpenStack cloud configuration and CSI snapshot components when snapshot operations are required.
