---
id: service-categories
title: "Service Categories"
sidebar_label: Service Categories
description: Generated service inventory organized by deployment blueprint. Generated from applications/blueprints and the catalog by hack/scripts/catalog.py.
doc_type: reference
audience: "platform engineers, operators, architects"
tags: [catalog, services, blueprints, reference, inventory]
---

# openCenter-gitops-base — Service Categories

> **Generated file.** Produced by `hack/scripts/catalog.py docs` from `applications/blueprints/*.yaml` and the per-service `catalog.yaml` fragments. Do not edit by hand — edit the blueprints or fragments and regenerate.

Service inventory organized by deployment blueprint. Services repeat across blueprints where they serve multiple profiles.

---

## Minimal

The smallest viable cluster. Provides networking, certificate management, storage, secrets, DNS, and basic observability. Enough to run stateless and stateful workloads with TLS.

| Service | Version | Purpose |
|---------|---------|---------|
| cert-manager | v1.21.2 | Automated TLS certificate management |
| metallb | 0.16.1 | Load balancer for bare-metal clusters (L2/BGP) |
| sealed-secrets | 2.20.0 | GitOps-friendly secret management |
| nodelocaldns | 2.4.0 | Per-node DNS caching agent |
| external-snapshotter | v8.2.1 | Volume snapshot management |
| longhorn | 1.12.1 | Distributed block storage |
| gateway-api | v0.0.0-latest | Next-generation ingress/gateway routing (Envoy Gateway) |
| observability/kube-prometheus-stack | 91.4.1 | Prometheus, Grafana, Alertmanager |

**CNI (choose one):**

| Service | Version | Purpose |
|---------|---------|---------|
| cilium | 1.20.2 | eBPF-based CNI with observability and security |
| calico | v3.32.2 | Standard L3 networking and network policy (Tigera Operator) |
| kube-ovn | v1.16.6 | OVN/OVS CNI with VPC, subnets, security groups, QoS |

---

## Enterprise

Production-hardened cluster. Adds identity management, policy enforcement, service mesh, container registry, backup/DR, RBAC automation, full observability stack, and database management.

| Service | Version | Purpose |
|---------|---------|---------|
| cert-manager | v1.21.2 | Automated TLS certificate management |
| metallb | 0.16.1 | Load balancer for bare-metal clusters (L2/BGP) |
| sealed-secrets | 2.20.0 | GitOps-friendly secret management |
| nodelocaldns | 2.4.0 | Per-node DNS caching agent |
| external-snapshotter | v8.2.1 | Volume snapshot management |
| longhorn | 1.12.1 | Distributed block storage |
| gateway-api | v0.0.0-latest | Next-generation ingress/gateway routing (Envoy Gateway) |
| observability/kube-prometheus-stack | 91.4.1 | Prometheus, Grafana, Alertmanager |
| external-dns | 1.22.0 | DNS record synchronization with external providers |
| keycloak | — | Identity and access management (OIDC/SSO) |
| istio | — | Service mesh for traffic management, security, and observability |
| harbor | 1.19.2 | Container registry with vulnerability scanning |
| kyverno | — | Kubernetes-native policy engine |
| rbac-manager | 2.0.0 | Declarative RBAC management automation |
| velero | 12.2.0 | Backup and disaster recovery |
| headlamp | 0.45.0 | Modern Kubernetes dashboard |
| olm | v0.34.0 | Operator Lifecycle Manager |
| postgres-operator | 2.0.2 | PostgreSQL HA cluster management |
| redis-operator | 0.26.1 | Redis multi-topology management |
| strimzi-kafka-operator | 0.50.0 | Apache Kafka lifecycle management |
| kured | 6.1.0 | Kubernetes reboot daemon for node maintenance |
| observability/loki | 7.3.0 | Log aggregation and querying |
| observability/mimir | 6.2.0 | Horizontally scalable long-term metrics storage |
| observability/tempo | 1.61.3 | Distributed tracing backend |
| observability/opentelemetry-kube-stack | 0.23.0 | OpenTelemetry collection framework |

**CNI (choose one):**

| Service | Version | Purpose |
|---------|---------|---------|
| cilium | 1.20.2 | eBPF-based CNI with observability and security |
| calico | v3.32.2 | Standard L3 networking and network policy (Tigera Operator) |
| kube-ovn | v1.16.6 | OVN/OVS CNI with VPC, subnets, security groups, QoS |

---

## AI/ML

Full machine learning and GenAI platform. Includes model training, inference serving, experiment tracking, feature stores, vector databases, notebook environments, job scheduling, and HPC workload management.

| Service | Version | Purpose |
|---------|---------|---------|
| cert-manager | v1.21.2 | Automated TLS certificate management |
| metallb | 0.16.1 | Load balancer for bare-metal clusters (L2/BGP) |
| sealed-secrets | 2.20.0 | GitOps-friendly secret management |
| nodelocaldns | 2.4.0 | Per-node DNS caching agent |
| external-snapshotter | v8.2.1 | Volume snapshot management |
| longhorn | 1.12.1 | Distributed block storage |
| gateway-api | v0.0.0-latest | Next-generation ingress/gateway routing (Envoy Gateway) |
| observability/kube-prometheus-stack | 91.4.1 | Prometheus, Grafana, Alertmanager |
| external-dns | 1.22.0 | DNS record synchronization with external providers |
| keycloak | — | Identity and access management (OIDC/SSO) |
| istio | — | Service mesh for traffic management, security, and observability |
| harbor | 1.19.2 | Container registry with vulnerability scanning |
| kyverno | — | Kubernetes-native policy engine |
| rbac-manager | 2.0.0 | Declarative RBAC management automation |
| velero | 12.2.0 | Backup and disaster recovery |
| headlamp | 0.45.0 | Modern Kubernetes dashboard |
| olm | v0.34.0 | Operator Lifecycle Manager |
| postgres-operator | 2.0.2 | PostgreSQL HA cluster management |
| redis-operator | 0.26.1 | Redis multi-topology management |
| strimzi-kafka-operator | 0.50.0 | Apache Kafka lifecycle management |
| kured | 6.1.0 | Kubernetes reboot daemon for node maintenance |
| observability/loki | 7.3.0 | Log aggregation and querying |
| observability/mimir | 6.2.0 | Horizontally scalable long-term metrics storage |
| observability/tempo | 1.61.3 | Distributed tracing backend |
| observability/opentelemetry-kube-stack | 0.23.0 | OpenTelemetry collection framework |
| node-feature-discovery | 0.19.0 | Hardware feature detection and node labeling |
| kueue | 0.19.5 | Job queueing and GPU resource management |
| kuberay-operator | 1.7.1 | Ray cluster orchestration for distributed compute |
| training-operator | 0.0.1 | Distributed ML training (PyTorch, TensorFlow, XGBoost) |
| kserve | v0.18.0 | AI/ML model inference serving (serverless) |
| triton-inference-server | v2.72.0 | NVIDIA high-performance model inference server |
| vllm | 0.1.12 | High-throughput LLM inference (production stack) |
| mlflow-operator | 1.1.0 | MLflow experiment and model lifecycle management |
| model-registry-operator | OLM | Model versioning and lifecycle registry |
| data-science-pipelines-operator | OLM | ML pipeline orchestration (Kubeflow Pipelines) |
| feast-operator | OLM | Feature store for consistent feature serving |
| trustyai-service-operator | OLM | AI explainability, fairness, and governance |
| milvus-operator | 1.3.10 | Vector database for RAG/GenAI workloads |
| jupyterhub | 4.4.2 | Multi-user notebook environments |
| slurm-operator | v1.2.0 | HPC workload management (Slurm on Kubernetes) |

**CNI (choose one):**

| Service | Version | Purpose |
|---------|---------|---------|
| cilium | 1.20.2 | eBPF-based CNI with observability and security |
| calico | v3.32.2 | Standard L3 networking and network policy (Tigera Operator) |
| kube-ovn | v1.16.6 | OVN/OVS CNI with VPC, subnets, security groups, QoS |

**GPU vendor (select per hardware fleet) (choose one):**

| Service | Version | Purpose |
|---------|---------|---------|
| nvidia-gpu-operator | v26.7.0 | NVIDIA GPU lifecycle management with MIG support |
| amd-gpu-operator | v1.5.1 | AMD Instinct GPU lifecycle management |

---

## Observability

Full-stack monitoring, logging, tracing, and telemetry collection.

| Service | Version | Purpose |
|---------|---------|---------|
| observability/kube-prometheus-stack | 91.4.1 | Prometheus, Grafana, Alertmanager |
| observability/loki | 7.3.0 | Log aggregation and querying |
| observability/mimir | 6.2.0 | Horizontally scalable long-term metrics storage |
| observability/tempo | 1.61.3 | Distributed tracing backend |
| observability/opentelemetry-kube-stack | 0.23.0 | OpenTelemetry collection framework |

---

## Storage

Persistent storage drivers and volume management. Choose based on infrastructure (bare-metal, OpenStack, vSphere, Ceph).

| Service | Version | Purpose |
|---------|---------|---------|
| longhorn | 1.12.1 | Distributed block storage |
| ceph-csi | — | Ceph RBD CSI storage driver |
| openstack-csi | 2.36.5 | OpenStack Cinder CSI driver |
| vsphere-csi | 3.8.1 | vSphere storage integration |
| external-snapshotter | v8.2.1 | Volume snapshot management |
| local-path-provisioner | v0.0.37 | Local path dynamic PV provisioner |

---

## Networking

CNI plugins and network infrastructure services. CNI is mutually exclusive — deploy exactly one.

| Service | Version | Purpose |
|---------|---------|---------|
| metallb | 0.16.1 | Load balancer for bare-metal clusters (L2/BGP) |
| gateway-api | v0.0.0-latest | Next-generation ingress/gateway routing (Envoy Gateway) |
| istio | — | Service mesh for traffic management, security, and observability |
| nodelocaldns | 2.4.0 | Per-node DNS caching agent |
| external-dns | 1.22.0 | DNS record synchronization with external providers |

**CNI (mutually exclusive) (choose one):**

| Service | Version | Purpose |
|---------|---------|---------|
| cilium | 1.20.2 | eBPF-based CNI with observability and security |
| calico | v3.32.2 | Standard L3 networking and network policy (Tigera Operator) |
| kube-ovn | v1.16.6 | OVN/OVS CNI with VPC, subnets, security groups, QoS |

---

## Security & Policy

Identity, secrets, access control, and policy enforcement.

| Service | Version | Purpose |
|---------|---------|---------|
| keycloak | — | Identity and access management (OIDC/SSO) |
| sealed-secrets | 2.20.0 | GitOps-friendly secret management |
| kyverno | — | Kubernetes-native policy engine |
| rbac-manager | 2.0.0 | Declarative RBAC management automation |
| cert-manager | v1.21.2 | Automated TLS certificate management |
| trustyai-service-operator | OLM | AI explainability, fairness, and governance |

---

## Data & Messaging

Databases, caches, message brokers, and feature stores.

| Service | Version | Purpose |
|---------|---------|---------|
| postgres-operator | 2.0.2 | PostgreSQL HA cluster management |
| redis-operator | 0.26.1 | Redis multi-topology management |
| strimzi-kafka-operator | 0.50.0 | Apache Kafka lifecycle management |
| milvus-operator | 1.3.10 | Vector database for RAG/GenAI workloads |
| feast-operator | OLM | Feature store for consistent feature serving |

---

## Cloud Provider Integration

Infrastructure-specific integrations. Deploy based on target cloud/hypervisor.

| Service | Version | Purpose |
|---------|---------|---------|
| openstack-ccm | 2.36.5 | OpenStack Cloud Controller Manager |
| openstack-csi | 2.36.5 | OpenStack Cinder CSI driver |
| vsphere-csi | 3.8.1 | vSphere storage integration |
| metallb | 0.16.1 | Load balancer for bare-metal clusters (L2/BGP) |

---

## HPC & Batch

High-performance computing and batch job scheduling.

| Service | Version | Purpose |
|---------|---------|---------|
| slurm-operator | v1.2.0 | HPC workload management (Slurm on Kubernetes) |
| kueue | 0.19.5 | Job queueing and GPU resource management |
| training-operator | 0.0.1 | Distributed ML training (PyTorch, TensorFlow, XGBoost) |
| kuberay-operator | 1.7.1 | Ray cluster orchestration for distributed compute |

---

## Operator Infrastructure

Services that manage other operators and their lifecycle.

| Service | Version | Purpose |
|---------|---------|---------|
| olm | v0.34.0 | Operator Lifecycle Manager |
| node-feature-discovery | 0.19.0 | Hardware feature detection and node labeling |
