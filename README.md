# openCenter GitOps Base

`openCenter-gitops-base` is the shared foundation for building and operating openCenter clusters.

It covers two parts of the platform lifecycle:

- `iac/` provisions the underlying infrastructure, renders Kubespray inventory and variables, and initiates Kubernetes cluster deployment through Kubespray
- `applications/` provides the reusable GitOps base for platform services deployed into Kubernetes clusters

The service base in this repository is intended to be consumed in two ways:

- directly by cluster repositories that apply cluster-specific overrides
- indirectly by the private enterprise repository, which imports this base and applies private source, image, and values rewrites

The `applications/` tree is managed with Flux CD and follows declarative, version-controlled GitOps patterns.

## Repository Layout

- `iac/` provisions infrastructure, renders Kubespray inputs, and initiates cluster bootstrap
- `applications/` contains the reusable base service definitions and policy resources
- `docs/` contains tutorials, how-to guides, references, and architecture documentation

For the complete directory layout, see [Directory Structure](docs/reference/directory-structure.md).

## Service Inventory

The base currently contains **47 service directories** under `applications/base/services/`. The list below is a filesystem inventory, not a statement that every entry is enabled or deployable by every consumer. Packaging and the declared catalog metadata are recorded in the generated [catalog lock](applications/catalog.lock.yaml) when a catalog fragment exists. `renderOwner` is catalog metadata; it does not verify an external CLI, consumer, or live-cluster deployment.

### Standalone service directories

| Service | Path | Declared catalog metadata (`renderOwner`) |
|---------|------|---------------------------|
| [amd-gpu-operator](applications/base/services/amd-gpu-operator/) | `applications/base/services/amd-gpu-operator/` | `renderOwner: none` |
| [calico](applications/base/services/calico/) | `applications/base/services/calico/` | `renderOwner: descriptor` |
| [cert-manager](applications/base/services/cert-manager/) | `applications/base/services/cert-manager/` | `renderOwner: descriptor` |
| [cilium](applications/base/services/cilium/) | `applications/base/services/cilium/` | `renderOwner: renderCatalog` |
| [data-science-pipelines-operator](applications/base/services/data-science-pipelines-operator/) | `applications/base/services/data-science-pipelines-operator/` | `renderOwner: none` |
| [external-dns](applications/base/services/external-dns/) | `applications/base/services/external-dns/` | `renderOwner: renderCatalog` |
| [external-snapshotter](applications/base/services/external-snapshotter/) | `applications/base/services/external-snapshotter/` | `renderOwner: renderCatalog` |
| [feast-operator](applications/base/services/feast-operator/) | `applications/base/services/feast-operator/` | `renderOwner: none` |
| [gateway-api](applications/base/services/gateway-api/) | `applications/base/services/gateway-api/` | `renderOwner: renderCatalog` |
| [harbor](applications/base/services/harbor/) | `applications/base/services/harbor/` | `renderOwner: descriptor` |
| [headlamp](applications/base/services/headlamp/) | `applications/base/services/headlamp/` | `renderOwner: renderCatalog` |
| [jupyterhub](applications/base/services/jupyterhub/) | `applications/base/services/jupyterhub/` | `renderOwner: none` |
| [keda](applications/base/services/keda/) | `applications/base/services/keda/` | `catalog.yaml` present; `renderOwner` not declared |
| [kserve](applications/base/services/kserve/) | `applications/base/services/kserve/` | `renderOwner: none` |
| [kube-ovn](applications/base/services/kube-ovn/) | `applications/base/services/kube-ovn/` | `renderOwner: none` |
| [kuberay-operator](applications/base/services/kuberay-operator/) | `applications/base/services/kuberay-operator/` | `renderOwner: none` |
| [kueue](applications/base/services/kueue/) | `applications/base/services/kueue/` | `renderOwner: none` |
| [kured](applications/base/services/kured/) | `applications/base/services/kured/` | `renderOwner: renderCatalog` |
| [local-path-provisioner](applications/base/services/local-path-provisioner/) | `applications/base/services/local-path-provisioner/` | `renderOwner: renderCatalog` |
| [longhorn](applications/base/services/longhorn/) | `applications/base/services/longhorn/` | `renderOwner: renderCatalog` |
| [metallb](applications/base/services/metallb/) | `applications/base/services/metallb/` | `renderOwner: renderCatalog` |
| [milvus-operator](applications/base/services/milvus-operator/) | `applications/base/services/milvus-operator/` | `renderOwner: none` |
| [mlflow-operator](applications/base/services/mlflow-operator/) | `applications/base/services/mlflow-operator/` | `renderOwner: none` |
| [model-registry-operator](applications/base/services/model-registry-operator/) | `applications/base/services/model-registry-operator/` | `renderOwner: none` |
| [node-feature-discovery](applications/base/services/node-feature-discovery/) | `applications/base/services/node-feature-discovery/` | `renderOwner: none` |
| [nodelocaldns](applications/base/services/nodelocaldns/) | `applications/base/services/nodelocaldns/` | `renderOwner: renderCatalog` |
| [nvidia-gpu-operator](applications/base/services/nvidia-gpu-operator/) | `applications/base/services/nvidia-gpu-operator/` | `renderOwner: none` |
| [olm](applications/base/services/olm/) | `applications/base/services/olm/` | `renderOwner: descriptor` |
| [openstack-ccm](applications/base/services/openstack-ccm/) | `applications/base/services/openstack-ccm/` | `renderOwner: renderCatalog` |
| [openstack-csi](applications/base/services/openstack-csi/) | `applications/base/services/openstack-csi/` | `renderOwner: renderCatalog` |
| [postgres-operator](applications/base/services/postgres-operator/) | `applications/base/services/postgres-operator/` | `renderOwner: renderCatalog` |
| [rbac-manager](applications/base/services/rbac-manager/) | `applications/base/services/rbac-manager/` | `renderOwner: renderCatalog` |
| [redis-operator](applications/base/services/redis-operator/) | `applications/base/services/redis-operator/` | `renderOwner: none` |
| [sealed-secrets](applications/base/services/sealed-secrets/) | `applications/base/services/sealed-secrets/` | `renderOwner: renderCatalog` |
| [slurm-operator](applications/base/services/slurm-operator/) | `applications/base/services/slurm-operator/` | `renderOwner: none` |
| [strimzi-kafka-operator](applications/base/services/strimzi-kafka-operator/) | `applications/base/services/strimzi-kafka-operator/` | `renderOwner: renderCatalog` |
| [training-operator](applications/base/services/training-operator/) | `applications/base/services/training-operator/` | `renderOwner: none` |
| [triton-inference-server](applications/base/services/triton-inference-server/) | `applications/base/services/triton-inference-server/` | `renderOwner: none` |
| [trustyai-service-operator](applications/base/services/trustyai-service-operator/) | `applications/base/services/trustyai-service-operator/` | `renderOwner: none` |
| [velero](applications/base/services/velero/) | `applications/base/services/velero/` | `renderOwner: renderCatalog` |
| [vllm](applications/base/services/vllm/) | `applications/base/services/vllm/` | `renderOwner: none` |
| [vsphere-csi](applications/base/services/vsphere-csi/) | `applications/base/services/vsphere-csi/` | `renderOwner: renderCatalog` |

### Composite service directories

These directories contain separately addressed child paths and are not a single root deployment target. The child paths below are taken from their catalog fragments and directory contents.

| Service | Deployable or staged children | Declared catalog metadata (`renderOwner`) |
|---------|-------------------------------|---------------------------------------------|
| [ceph-csi](applications/base/services/ceph-csi/) | [`ceph-csi-rbd`](applications/base/services/ceph-csi/ceph-csi-rbd/); `namespace` is a prerequisite | `renderOwner: renderCatalog` |
| [istio](applications/base/services/istio/) | `base`, `istiod`, `gateway`; `namespace` and `sources` are prerequisites | `renderOwner: renderCatalog` |
| [keycloak](applications/base/services/keycloak/) | `00-postgres`, `10-operator`, `20-keycloak`, `30-oidc-rbac` | `renderOwner: descriptor` |
| [kyverno](applications/base/services/kyverno/) | `policy-engine`, `default-ruleset` | `renderOwner: renderCatalog` |
| [observability](applications/base/services/observability/) | `kube-prometheus-stack`, `loki`, `mimir`, `tempo`, `opentelemetry-kube-stack`; `namespace` and `sources` are prerequisites | `renderOwner: renderCatalog` |

### Inventory boundaries

- **Implemented here:** A directory means that this repository contains a base manifest set at that path. The base may be Helm-, OLM-, remote-kustomize-, Git-, or composite-shaped; inspect the path and its catalog fragment rather than assuming one deployment pattern.
- **Catalog metadata:** `renderOwner` is a declared catalog field whose enum values are `renderCatalog`, `descriptor`, and `none`. These values describe metadata in this repository; they do not verify an external CLI, consumer, or live-cluster deployment.
- **Planned work:** This repository does not turn `renderOwner: none` or a missing catalog entry into a roadmap commitment. Future catalog changes must be established by the owning tooling or consumer project.
- **Consumer-owned configuration:** Cluster overlays own cluster-specific values, secrets, custom resources, and activation. The private enterprise repository owns private source, image, values, and enterprise-component rewrites. This base repository does not promise those consumer-side resources.

The catalog currently has fragments and aggregate entries for all 47 service directories, including `keda`. Keep the inventory and generated aggregate synchronized instead of inventing version or deployment claims.

### Security Policies

| Policy | Scope | Purpose |
|--------|-------|---------|
| **[network-policies](applications/policies/network-policies/)** | Various | Kubernetes network segmentation |
| **[pod-security-policies](applications/policies/pod-security-policies/)** | Various | Pod security standards enforcement |
| **[rbac](applications/policies/rbac/)** | Various | Role-based access control |

## Documentation

Use the documentation set under `docs/` together with the service README files for architecture, onboarding, configuration, and troubleshooting.

- [Infrastructure as Code](iac/README.md) - Provision clusters and bootstrap Kubernetes
- [Documentation Index](docs/index.md) - Lifecycle layout: getting-started, operations, reference, concepts, release, contributing
- [Getting Started](docs/getting-started/getting-started.md) - Deploy your first service
- [Service Deployment Patterns](docs/operations/service-deployment-patterns.md) - Choose community or enterprise sourcing
- [Helm Service Onboarding](docs/operations/helm-service-onboarding.md) - Onboard Helm-based services
- [OLM Service Onboarding](docs/operations/olm-service-onboarding.md) - Onboard OLM-based services
- [Operator CR Service Onboarding](docs/operations/operator-cr-service-onboarding.md) - Onboard operator-managed custom resources
- [Add a Helm Service to the Community Repo](docs/operations/add-helm-service-to-community-repo.md) - Add a shared Helm service to `applications/base/services/`
- [Service Reference Library](docs/reference/services/index.md) - Per-service reference pages
- [Service Configuration Guides](docs/operations/services/index.md) - Configuration and troubleshooting for selected services
