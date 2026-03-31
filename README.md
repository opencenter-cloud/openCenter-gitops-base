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
- `applications/` contains the reusable base service definitions, managed services, and policy resources
- `docs/` contains tutorials, how-to guides, references, and architecture documentation

For the complete directory layout, see [Directory Structure](docs/reference/directory-structure.md).

## Available Applications

### Core Services

| Service | Namespace | Version | Purpose | Documentation |
|---------|-----------|---------|---------|---------------|
| **[cert-manager](applications/base/services/cert-manager/)** | `cert-manager` | `v1.18.2` | Automated TLS certificate management | [README](applications/base/services/cert-manager/README.md) |
| **[external-snapshotter](applications/base/services/external-snapshotter/)** | `external-snapshotter` | `v8.2.1` | Volume snapshot management | [README](applications/base/services/external-snapshotter/README.md) |
| **[gateway-api](applications/base/services/gateway-api/)** | `envoy-gateway-system` | `v0.0.0-latest` | Next-generation ingress API | [README](applications/base/services/gateway-api/README.md) |
| **[harbor](applications/base/services/harbor/)** | `harbor` | `1.17.2` | Container registry with security scanning | [README](applications/base/services/harbor/README.md) |
| **[headlamp](applications/base/services/headlamp/)** | `headlamp` | `0.35.0` | Modern Kubernetes dashboard | [README](applications/base/services/headlamp/README.md) |
| **[istio](applications/base/services/istio/)** | `istio-system` | `1.28.3` | Service mesh for traffic management, security, and observability | [README](applications/base/services/istio/README.md) |
| **[keycloak](applications/base/services/keycloak/)** | `keycloak` | `26.4.2` | Identity and access management | [README](applications/base/services/keycloak/README.md) |
| **[kyverno](applications/base/services/kyverno/)** | `kyverno` | `3.6.0` | Kubernetes-native policy engine | [README](applications/base/services/kyverno/README.md) |
| **[longhorn](applications/base/services/longhorn/)** | `longhorn-system` | `1.11.0` | Distributed block storage | [README](applications/base/services/longhorn/README.md) |
| **[metallb](applications/base/services/metallb/)** | `metallb-system` | `0.15.2` | Load balancer for bare-metal clusters | [README](applications/base/services/metallb/README.md) |
| **[olm](applications/base/services/olm/)** | `olm` | `v0.34.0` | Operator Lifecycle Manager | [README](applications/base/services/olm/README.md) |
| **[openstack-ccm](applications/base/services/openstack-ccm/)** | `openstack-ccm` | `2.33.1` | OpenStack Cloud Controller Manager | [README](applications/base/services/openstack-ccm/README.md) |
| **[openstack-csi](applications/base/services/openstack-csi/)** | `openstack-csi` | `2.33.1` | OpenStack Cinder CSI driver | [README](applications/base/services/openstack-csi/README.md) |
| **[postgres-operator](applications/base/services/postgres-operator/)** | `postgres-operator` | `1.14.0` | PostgreSQL cluster management | [README](applications/base/services/postgres-operator/README.md) |
| **[rbac-manager](applications/base/services/rbac-manager/)** | `rbac-manager` | `1.21.1` | RBAC management automation | [README](applications/base/services/rbac-manager/README.md) |
| **[sealed-secrets](applications/base/services/sealed-secrets/)** | `sealed-secrets` | `2.17.3` | GitOps-friendly secret management | [README](applications/base/services/sealed-secrets/README.md) |
| **[strimzi-kafka-operator](applications/base/services/strimzi-kafka-operator/)** | `kafka-system` | `0.50.0` | Kubernetes operator for Apache Kafka | [README](applications/base/services/strimzi-kafka-operator/README.md) |
| **[velero](applications/base/services/velero/)** | `velero` | `10.1.1` | Backup and disaster recovery | [README](applications/base/services/velero/README.md) |
| **[vsphere-csi](applications/base/services/vsphere-csi/)** | `vmware-system-csi` | `3.8.1` | vSphere storage integration | [README](applications/base/services/vsphere-csi/README.md) |

### Observability Stack

| Component | Namespace | Version | Purpose | Documentation |
|-----------|-----------|---------|---------|---------------|
| **[kube-prometheus-stack](applications/base/services/observability/kube-prometheus-stack/)** | `observability` | `77.6.0` | Prometheus, Grafana, Alertmanager | [README](applications/base/services/observability/kube-prometheus-stack/README.md) |
| **[loki](applications/base/services/observability/loki/)** | `observability` | `6.45.2` | Log aggregation and storage | [README](applications/base/services/observability/loki/README.md) |
| **[mimir](applications/base/services/observability/mimir/)** | `observability` | `6.0.3` | Horizontally scalable long-term metrics storage | [README](applications/base/services/observability/mimir/README.md) |
| **[tempo](applications/base/services/observability/tempo/)** | `observability` | `1.55.0` | Distributed tracing backend | [README](applications/base/services/observability/tempo/README.md) |
| **[opentelemetry-kube-stack](applications/base/services/observability/opentelemetry-kube-stack/)** | `observability` | `0.11.1` | OpenTelemetry collection framework | [README](applications/base/services/observability/opentelemetry-kube-stack/README.md) |

### Security Policies

| Policy | Scope | Purpose |
|--------|-------|---------|
| **[network-policies](applications/policies/network-policies/)** | Various | Kubernetes network segmentation |
| **[pod-security-policies](applications/policies/pod-security-policies/)** | Various | Pod security standards enforcement |
| **[rbac](applications/policies/rbac/)** | Various | Role-based access control |

## Documentation

Use the documentation set under `docs/` together with the service README files for architecture, onboarding, configuration, and troubleshooting.

### Start Here

- [Infrastructure as Code](iac/README.md) - Cluster provisioning, Kubespray inventory generation, and Kubernetes bootstrap flow
- [Documentation Index](docs/index.md) - Main entry point for tutorials, how-to guides, references, and explanations
- [Getting Started Tutorial](docs/tutorials/getting-started.md) - Deploy a first service end to end
- [Service Deployment Patterns](docs/how-to/service-deployment-patterns.md) - How cluster repos consume services from the community or enterprise repo
- [Helm Service Onboarding](docs/how-to/helm-service-onboarding.md) - Onboard Helm-based services such as cert-manager, Harbor, Longhorn, MetalLB, and Loki
- [OLM Service Onboarding](docs/how-to/olm-service-onboarding.md) - Onboard services whose operator is installed through OLM, such as Keycloak
- [Operator CR Service Onboarding](docs/how-to/operator-cr-service-onboarding.md) - Onboard services where Helm installs the operator and the cluster overlay creates Kafka or PostgreSQL custom resources
- [Add a Service to the Community Repo](docs/how-to/add-service-to-community-repo.md) - Add a new shared service under `applications/base/services/`
- [Service Catalog](docs/reference/service-catalog.md) - Service inventory, dependencies, and configuration surfaces

### Service Docs

- Service directories under `applications/base/services/` contain repo-local deployment context and links to supporting docs
- [Service Reference Library](docs/reference/services/index.md) - Per-service overviews, integration points, examples, and upstream references
- [Service Configuration Guides](docs/how-to/services/index.md) - Practical override patterns, validation steps, and troubleshooting guidance for selected services
