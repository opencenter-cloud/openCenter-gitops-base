# OpenStack Cloud Controller Manager (CCM) – Base Configuration

This directory contains the **base manifests** for deploying the [OpenStack Cloud Controller Manager(CCM)](https://github.com/kubernetes/cloud-provider-openstack), which integrates Kubernetes with OpenStack cloud services for networking, storage, and instance management.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/openstack-ccm.md).

**About OpenStack Cloud Controller Manager:**

- Enables Kubernetes to interact directly with **OpenStack APIs** for managing cloud resources.  
- Handles Kubernetes **node lifecycle management**, such as attaching instance metadata and updating node addresses.  
- Provides **LoadBalancer service integration** by provisioning OpenStack **Octavia** load balancers.  
- Updates node routes and network configurations in coordination with OpenStack **Neutron**.  
- Commonly used in private or hybrid cloud environments where Kubernetes clusters run on OpenStack infrastructure.  
- Improves automation, consistency, and observability of Kubernetes workloads on OpenStack-based platforms.  

## Repository implementation

- Source path: `applications/base/services/openstack-ccm/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `openstack-ccm` and reads `openstack-ccm-values-base` plus the optional `openstack-ccm-values-override` Secret.
- Base values: `helm-values/hardened-values-2.36.5.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/openstack-ccm/` to validate the local manifests. The base does not contain OpenStack credentials, cloud configuration, or an Octavia/network policy. The cluster must provide valid OpenStack connectivity and permissions before the controller can manage nodes or load balancers.
