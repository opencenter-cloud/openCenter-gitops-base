# openCenter-gitops-base — Service Categories

Service inventory organized by deployment profile. Services repeat across categories where they serve multiple profiles.

---

## Minimal

The smallest viable cluster. Provides networking, certificate management, storage, secrets, DNS, and basic observability. Enough to run stateless and stateful workloads with TLS.

| Service | Version | Purpose |
|---------|---------|---------|
| cert-manager | v1.18.2 | Automated TLS certificate management |
| metallb | 0.15.2 | Load balancer for bare-metal clusters |
| sealed-secrets | 2.17.3 | GitOps-friendly secret management |
| nodelocaldns | 2.4.0 | Per-node DNS caching |
| external-snapshotter | v8.2.1 | Volume snapshot support |
| longhorn | 1.11.0 | Distributed block storage (default for bare-metal) |
| kube-prometheus-stack | 77.6.0 | Prometheus + Grafana + Alertmanager |
| gateway-api | v0.0.0-latest | Next-generation ingress API |

**CNI (choose one):**

| Service | Version | Purpose |
|---------|---------|---------|
| cilium | 1.19.4 | eBPF-based networking, observability, security |
| calico | v3.32.0 | Standard L3 networking + network policy |
| kube-ovn | v1.16.2 | OVN/OVS advanced networking (VPC, subnets, QoS) |

---

## Enterprise

Production-hardened cluster. Adds identity management, policy enforcement, service mesh, container registry, backup/DR, RBAC automation, full observability stack, and database management.

| Service | Version | Purpose |
|---------|---------|---------|
| cert-manager | v1.18.2 | Automated TLS certificate management |
| metallb | 0.15.2 | Load balancer for bare-metal clusters |
| sealed-secrets | 2.17.3 | GitOps-friendly secret management |
| nodelocaldns | 2.4.0 | Per-node DNS caching |
| external-snapshotter | v8.2.1 | Volume snapshot support |
| longhorn | 1.11.0 | Distributed block storage |
| gateway-api | v0.0.0-latest | Next-generation ingress API |
| external-dns | latest | DNS record synchronization with external providers |
| keycloak | 26.4.2 | Identity and access management (OIDC/SSO) |
| istio | 1.28.3 | Service mesh (mTLS, traffic management, observability) |
| harbor | 1.17.2 | Container registry with vulnerability scanning |
| kyverno | 3.6.0 | Kubernetes-native policy engine |
| rbac-manager | 1.21.1 | RBAC automation |
| velero | 10.1.1 | Backup and disaster recovery |
| headlamp | 0.35.0 | Kubernetes dashboard |
| olm | v0.34.0 | Operator Lifecycle Manager |
| postgres-operator | 1.14.0 | PostgreSQL cluster management |
| redis-operator | 0.25.0 | Redis multi-topology management |
| strimzi-kafka-operator | 0.50.0 | Apache Kafka on Kubernetes |
| kube-prometheus-stack | 77.6.0 | Prometheus + Grafana + Alertmanager |
| loki | 6.45.2 | Log aggregation |
| mimir | 6.0.3 | Long-term metrics storage |
| tempo | 1.55.0 | Distributed tracing |
| opentelemetry-kube-stack | 0.11.1 | OpenTelemetry collection framework |

**CNI (choose one):**

| Service | Version | Purpose |
|---------|---------|---------|
| cilium | 1.19.4 | eBPF-based networking, observability, security |
| calico | v3.32.0 | Standard L3 networking + network policy |
| kube-ovn | v1.16.2 | OVN/OVS advanced networking (VPC, subnets, QoS) |

---

## AI/ML

Full machine learning and GenAI platform. Includes model training, inference serving, experiment tracking, feature stores, vector databases, notebook environments, job scheduling, and HPC workload management.

| Service | Version | Purpose |
|---------|---------|---------|
| nvidia-gpu-operator | v26.3.2 | NVIDIA GPU lifecycle management (MIG support) |
| amd-gpu-operator | latest | AMD Instinct GPU management |
| node-feature-discovery | latest | Hardware feature detection and node labeling |
| kueue | 0.18.0 | Job queueing and GPU resource management |
| kuberay-operator | 1.4.2 | Distributed computing (Ray clusters) |
| training-operator | 0.0.1 | Distributed ML training (PyTorch, TensorFlow, XGBoost) |
| kserve | v0.18.0 | Model inference serving (serverless) |
| triton-inference-server | v2.69.0 | NVIDIA high-performance inference server |
| vllm | latest | High-throughput LLM inference (PagedAttention) |
| mlflow-operator | 1.1.0 | MLflow experiment and model lifecycle management |
| model-registry-operator | OLM | Model versioning and lifecycle registry |
| data-science-pipelines-operator | OLM | ML pipeline orchestration (Kubeflow Pipelines) |
| feast-operator | OLM | Feature store for consistent feature serving |
| trustyai-service-operator | OLM | AI explainability, fairness, and governance |
| milvus-operator | 1.3.7 | Vector database for RAG/GenAI |
| jupyterhub | 4.4.0 | Multi-user notebook environments |
| slurm-operator | latest | HPC workload management (Slurm on K8s) |

---

## Observability

Full-stack monitoring, logging, tracing, and telemetry collection.

| Service | Version | Purpose |
|---------|---------|---------|
| kube-prometheus-stack | 77.6.0 | Prometheus, Grafana, Alertmanager |
| loki | 6.45.2 | Log aggregation and querying |
| mimir | 6.0.3 | Horizontally scalable long-term metrics storage |
| tempo | 1.55.0 | Distributed tracing backend |
| opentelemetry-kube-stack | 0.11.1 | OpenTelemetry collectors and instrumentation |

---

## Storage

Persistent storage drivers and volume management. Choose based on infrastructure (bare-metal, OpenStack, vSphere, Ceph).

| Service | Version | Purpose |
|---------|---------|---------|
| longhorn | 1.11.0 | Distributed block storage (bare-metal, any infrastructure) |
| ceph-csi | 3.17.0 | Ceph RBD CSI driver (external Ceph clusters) |
| openstack-csi | 2.33.1 | OpenStack Cinder CSI driver |
| vsphere-csi | 3.8.1 | vSphere storage integration |
| external-snapshotter | v8.2.1 | Volume snapshot management (required by most CSI drivers) |

---

## Networking

CNI plugins and network infrastructure services. CNI is mutually exclusive — deploy exactly one.

| Service | Version | Purpose |
|---------|---------|---------|
| cilium | 1.19.4 | eBPF-based CNI with built-in observability and security |
| calico | v3.32.0 | BGP/VXLAN-based CNI via Tigera Operator |
| kube-ovn | v1.16.2 | OVN/OVS CNI with VPC, subnets, security groups, QoS |
| metallb | 0.15.2 | Bare-metal load balancer (L2/BGP) |
| gateway-api | v0.0.0-latest | Next-generation ingress/gateway routing |
| istio | 1.28.3 | Service mesh (mTLS, traffic splitting, observability) |
| nodelocaldns | 2.4.0 | Per-node DNS cache |
| external-dns | latest | Sync K8s resources to external DNS providers |

---

## Security & Policy

Identity, secrets, access control, and policy enforcement.

| Service | Version | Purpose |
|---------|---------|---------|
| keycloak | 26.4.2 | Identity provider (OIDC, SSO, SAML) |
| sealed-secrets | 2.17.3 | Encrypt secrets for GitOps storage |
| kyverno | 3.6.0 | Policy engine (admission control, validation, mutation) |
| rbac-manager | 1.21.1 | Declarative RBAC management |
| cert-manager | v1.18.2 | Certificate lifecycle automation |
| trustyai-service-operator | OLM | AI governance, fairness, and explainability |

**Security Policies (Kyverno rulesets):**

| Policy Set | Purpose |
|------------|---------|
| network-policies | Kubernetes network segmentation |
| pod-security-policies | Pod security standards enforcement |
| rbac | Role-based access control rules |

---

## Data & Messaging

Databases, caches, message brokers, and feature stores.

| Service | Version | Purpose |
|---------|---------|---------|
| postgres-operator | 1.14.0 | PostgreSQL HA cluster management |
| redis-operator | 0.25.0 | Redis (standalone, cluster, replication, sentinel) |
| strimzi-kafka-operator | 0.50.0 | Apache Kafka lifecycle management |
| milvus-operator | 1.3.7 | Vector database (GenAI/RAG workloads) |
| feast-operator | OLM | Feature store for ML feature serving |

---

## Cloud Provider Integration

Infrastructure-specific integrations. Deploy based on target cloud/hypervisor.

| Service | Version | Target | Purpose |
|---------|---------|--------|---------|
| openstack-ccm | 2.33.1 | OpenStack | Cloud Controller Manager (LB, routes, zones) |
| openstack-csi | 2.33.1 | OpenStack | Cinder block storage CSI driver |
| vsphere-csi | 3.8.1 | vSphere | vSphere storage integration |
| metallb | 0.15.2 | Bare-metal | L2/BGP load balancer |

---

## HPC & Batch

High-performance computing and batch job scheduling.

| Service | Version | Purpose |
|---------|---------|---------|
| slurm-operator | latest | Slurm HPC cluster management on Kubernetes |
| kueue | 0.18.0 | Job queueing with fair-sharing and resource quotas |
| training-operator | 0.0.1 | Distributed training jobs (PyTorch, TF, XGBoost) |
| kuberay-operator | 1.4.2 | Ray cluster orchestration for distributed compute |

---

## Operator Infrastructure

Services that manage other operators and their lifecycle.

| Service | Version | Purpose |
|---------|---------|---------|
| olm | v0.34.0 | Operator Lifecycle Manager (required by OLM-based services) |
| node-feature-discovery | latest | Hardware detection (required by GPU operators) |

---

## Notes

- **CNI is mutually exclusive.** Deploy exactly one of: Cilium, Calico, or Kube-OVN.
- **OLM-based services** (data-science-pipelines-operator, feast-operator, model-registry-operator, trustyai-service-operator) require the OLM service to be deployed first.
- **GPU operators** (NVIDIA, AMD) benefit from node-feature-discovery for automatic hardware labeling. Both GPU operators bundle NFD as a sub-chart — disable it if deploying NFD standalone.
- **Storage is infrastructure-dependent.** Use Longhorn for bare-metal, OpenStack-CSI for OpenStack, vSphere-CSI for VMware, or Ceph-CSI for external Ceph clusters.
- **cert-manager** is a near-universal dependency — required by GPU operators, redis-operator, milvus-operator, slurm-operator, and many webhook-based services.
