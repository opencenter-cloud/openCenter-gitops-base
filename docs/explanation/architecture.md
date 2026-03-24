---
id: architecture-explanation
title: "Architecture Explanation"
sidebar_label: Architecture
description: Architectural design, decisions, and rationale behind the openCenter-gitops-base platform.
doc_type: explanation
audience: "architects, platform engineers"
tags: [architecture, gitops, fluxcd, design]
---

# Architecture Explanation

**Type:** Explanation  
**Audience:** Architects, platform engineers  
**Last Updated:** 2026-03-24

This document explains the architectural design, decisions, and rationale behind openCenter-gitops-base.

---

## Overview

openCenter-gitops-base is a **GitOps-managed Kubernetes platform** that provides production-ready infrastructure services using FluxCD. It delivers a complete stack including observability, storage, security, and networking components for Kubernetes clusters on OpenStack and vSphere.

### Design Philosophy

1. **GitOps-First** - Git is the single source of truth for cluster state
2. **Declarative Configuration** - All resources defined as Kubernetes manifests
3. **Automated Reconciliation** - FluxCD continuously syncs desired state
4. **Security by Default** - SOPS encryption, hardened Helm values, policy enforcement
5. **Multi-Cloud** - Provider-agnostic with OpenStack and vSphere support
6. **Composable Base** - Shared base services consumed by cluster and enterprise overlays

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Git Repository                          │
│              (openCenter-gitops-base)                           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Base Services (applications/base/services/)             │   │
│  │  - HelmRelease definitions                               │   │
│  │  - Kustomize manifests                                   │   │
│  │  - Base values files                                     │   │
│  │  - Upstream public chart sources                         │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ FluxCD Reconciliation
                              │ (GitRepository → Kustomization → HelmRelease)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Platform Services Layer                                 │   │
│  │  - cert-manager (TLS)                                    │   │
│  │  - kyverno (policy)                                      │   │
│  │  - keycloak (IAM)                                        │   │
│  │  - longhorn (storage)                                    │   │
│  │  - velero (backup)                                       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Observability Layer                                     │   │
│  │  - Prometheus (metrics)                                  │   │
│  │  - Loki (logs)                                           │   │
│  │  - Tempo (traces)                                        │   │
│  │  - Grafana (visualization)                               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Networking Layer                                        │   │
│  │  - MetalLB (load balancing)                              │   │
│  │  - Envoy Gateway / Istio (ingress)                       │   │
│  │  - Calico (CNI)                                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Application Layer                                       │   │
│  │  - Customer applications                                 │   │
│  │  - Managed services                                      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Layered Architecture

The platform is organized into distinct layers with clear responsibilities:

**Layer 1: GitOps Control Plane**
- FluxCD controllers (source, kustomize, helm)
- Git repository sources
- SOPS secret decryption
- Reconciliation loop (5-minute interval)

**Layer 2: Platform Services**
- Certificate management (cert-manager)
- Policy enforcement (Kyverno)
- Identity management (Keycloak)
- Storage (Longhorn, vSphere CSI, OpenStack CSI)
- Backup/DR (Velero)

**Layer 3: Observability**
- Metrics collection (Prometheus, OpenTelemetry)
- Log aggregation (Loki)
- Distributed tracing (Tempo)
- Visualization (Grafana)

**Layer 4: Networking**
- Load balancing (MetalLB)
- Ingress (Envoy Gateway, Istio)
- CNI (Calico)
- Service mesh (Istio - optional)

**Layer 5: Applications**
- Customer workloads
- Managed services

---

## Key Architectural Decisions

### ADR-001: GitOps with FluxCD

**Decision:** Use FluxCD for GitOps-based cluster management

**Rationale:**
- **Declarative:** All cluster state defined in Git
- **Automated:** Continuous reconciliation without manual intervention
- **Auditable:** Git history provides complete audit trail
- **Drift detection:** Automatically corrects manual changes
- **Multi-tenancy:** Namespace-scoped reconciliation

**Alternatives Considered:**
- ArgoCD: More UI-focused, heavier resource footprint
- Manual kubectl: Not scalable, no drift detection
- Helm CLI: No continuous reconciliation

**Trade-offs:**
- Requires FluxCD expertise for troubleshooting
- Reconciliation delays (5-15 minutes)
- Dependency management complexity

### ADR-002: HelmRelease for Service Deployment

**Decision:** Deploy all services via FluxCD HelmRelease CRD

**Rationale:**
- **Standardization:** Consistent deployment pattern across all services
- **Helm ecosystem:** Leverage existing Helm charts
- **Values management:** Base values in this repo, optional override values from consuming overlays
- **Drift detection:** Automatic correction of manual changes
- **Rollback:** Built-in rollback capabilities

**Pattern:**
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
spec:
  interval: 5m
  timeout: 10m
  driftDetection:
    mode: enabled
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: 0  # Manual intervention for upgrades
```

**Trade-offs:**
- Requires Helm chart availability
- Complex values merging
- Debugging requires FluxCD knowledge

### ADR-003: Base Plus Overlay Values

**Decision:** Keep required base values in `openCenter-gitops-base` and allow consuming repositories to supply optional override values

**Rationale:**
- **Separation of concerns:** Base repo owns reusable defaults, consuming repos own environment-specific customization
- **No base modification:** Cluster-specific changes happen outside the base repo
- **Reuse:** The same base service can be consumed by public cluster overlays or by private enterprise overlays
- **Maintainability:** Base chart and values upgrades stay localized to the base repo

**Hierarchy in practice:**
1. Chart defaults (from upstream chart)
2. Base values from this repo
3. Optional override values supplied by a consuming repo or cluster overlay

**Additional enterprise values, when used, are supplied by the private enterprise repository rather than stored in this repo.**

**Trade-offs:**
- Requires consumers to understand where override values are sourced
- Final rendered values may span multiple repositories
- Debugging merged values requires checking the consuming overlay as well as the base

### ADR-004: Enterprise Composition in the Private Repo

**Decision:** Keep enterprise Kustomize components in the private enterprise repository, not in `openCenter-gitops-base`

**Rationale:**
- **Public base stays clean:** No private registry or enterprise-only source wiring in this repo
- **Enterprise stays additive:** The private repo imports the base path and patches it
- **Separation of ownership:** Base repo owns shared service definitions; enterprise repo owns private artifacts and hardened enterprise deltas
- **Reusability:** Public consumers can use the base directly without carrying enterprise-specific structure

**Pattern:**
```text
openCenter-gitops-base
  -> applications/base/services/<service>

openCenter-gitops-enterprise
  -> overlays/install/kustomization.yaml imports the base path
  -> private enterprise patches or components adjust sourceRef, images, and enterprise values
```

**Trade-offs:**
- Understanding the full enterprise deployment requires reading two repositories
- Version alignment between base and enterprise overlays must be maintained deliberately
- Troubleshooting enterprise deployments requires checking both the base and enterprise layers

### ADR-005: SOPS for Secret Management

**Decision:** Use SOPS with age encryption for secrets in Git

**Rationale:**
- **Git-safe:** Encrypted secrets can be committed
- **Asymmetric encryption:** Public key for encryption, private key for decryption
- **FluxCD integration:** Automatic decryption during reconciliation
- **Selective encryption:** Encrypt only sensitive fields
- **Offline decryption:** Possible with private key

**Workflow:**
1. Generate age keypair per cluster
2. Configure `.sops.yaml` with age public key
3. Encrypt secrets: `sops -e -i secret.yaml`
4. Commit encrypted secrets to Git
5. FluxCD decrypts using age private key (stored in K8s secret)

**Alternatives Considered:**
- Sealed Secrets: Requires cluster for decryption, no offline access
- External Secrets Operator: Requires external infrastructure (Vault, cloud KMS)
- Plaintext: Insecure, compliance failure

**Trade-offs:**
- Age key loss = secret recovery failure
- Requires SOPS CLI for local operations
- Key rotation is manual process

### ADR-006: Multi-Component Services

**Decision:** Use numbered directories for services with multiple components

**Rationale:**
- **Deployment order:** Numeric prefix ensures correct order
- **Dependency clarity:** Visual indication of dependencies
- **Independent management:** Each component can be managed separately
- **FluxCD dependencies:** Explicit `dependsOn` in Kustomizations

**Example (Keycloak):**
```
keycloak/
├── 00-postgres/      # Database first
├── 10-operator/      # Operator second
├── 20-keycloak/      # Instance third
└── 30-oidc-rbac/     # Configuration last
```

**Trade-offs:**
- More complex directory structure
- Requires understanding of deployment order
- More FluxCD Kustomization resources

---

## Data Flows

### GitOps Reconciliation Flow

```
1. Developer commits change to Git
   ↓
2. FluxCD Source Controller detects change (15min interval)
   ↓
3. Source Controller pulls Git repository
   ↓
4. Kustomize Controller processes Kustomization (5min interval)
   ↓
5. Kustomize Controller decrypts SOPS secrets (if configured)
   ↓
6. Kustomize Controller applies manifests to cluster
   ↓
7. Helm Controller processes HelmRelease
   ↓
8. Helm Controller installs/upgrades Helm chart
   ↓
9. Kubernetes creates/updates resources
   ↓
10. Drift detection monitors for manual changes
    ↓
11. Automatic remediation if drift detected
```

### Secret Management Flow

```
1. Developer creates secret manifest
   ↓
2. Developer encrypts with SOPS: sops -e -i secret.yaml
   ↓
3. Developer commits encrypted secret to Git
   ↓
4. FluxCD Source Controller pulls repository
   ↓
5. Kustomize Controller processes Kustomization
   ↓
6. Kustomize Controller decrypts using age key
   ↓
7. Decrypted secret applied to cluster
   ↓
8. Application consumes secret
```

### Observability Data Flow

```
Application Pods
  │
  ├─ Metrics (Prometheus format, /metrics endpoint)
  │  ↓
  │  ServiceMonitor/PodMonitor (Prometheus Operator)
  │  ↓
  │  Prometheus (scrape, 30s interval)
  │  ↓
  │  Remote Write → Mimir (long-term storage)
  │
  ├─ Logs (stdout/stderr)
  │  ↓
  │  OpenTelemetry Collector (OTLP)
  │  ↓
  │  Loki (log aggregation)
  │
  └─ Traces (OTLP)
     ↓
     OpenTelemetry Collector
     ↓
     Tempo (trace storage)

All data visualized in Grafana
```

### Ingress Traffic Flow

```
External Client (HTTPS)
  ↓
MetalLB LoadBalancer (L2/BGP)
  ↓
Envoy Gateway / Istio Gateway
  │
  ├─ TLS Termination (cert-manager certificates)
  ├─ Rate Limiting (configured per HTTPRoute)
  ├─ Authentication (Keycloak OIDC - optional)
  └─ Authorization (Kyverno policies - optional)
  ↓
Service Mesh (Istio - optional)
  │
  ├─ mTLS (service-to-service encryption)
  ├─ Traffic Management (retries, timeouts, circuit breakers)
  └─ Telemetry (metrics, logs, traces)
  ↓
Application Service
  ↓
Application Pod
```

---

## Component Interactions

### FluxCD Components

**Source Controller:**
- Polls Git repositories (15min interval)
- Polls Helm repositories (1h interval)
- Provides artifacts to other controllers
- Handles authentication (SSH keys, HTTP basic auth)

**Kustomize Controller:**
- Processes Kustomization resources (5min interval)
- Applies manifests to cluster
- Decrypts SOPS secrets
- Manages dependencies (`dependsOn`)
- Performs health checks
- Prunes deleted resources

**Helm Controller:**
- Processes HelmRelease resources (5min interval)
- Installs/upgrades Helm charts
- Merges values from multiple sources
- Performs drift detection
- Handles install/upgrade remediation
- Manages rollbacks

### Service Dependencies

**Critical Path:**
```
flux-system (bootstrap)
  ↓
cert-manager (TLS certificates)
  ↓
kyverno (policy enforcement)
  ↓
keycloak (authentication)
  ├─ postgres (database)
  ├─ operator (Keycloak operator)
  └─ instance (Keycloak server)
  ↓
observability (monitoring)
  ├─ kube-prometheus-stack
  ├─ loki
  ├─ tempo
  └─ opentelemetry
```

**Storage Dependencies:**
```
longhorn OR vsphere-csi OR openstack-csi
  ↓
velero (backup/restore)
  ↓
stateful applications
```

**Networking Dependencies:**
```
metallb (load balancing)
  ↓
gateway-api OR istio (ingress)
  ↓
cert-manager (TLS)
  ↓
external traffic
```

---

## Security Architecture

### Trust Boundaries

1. **External → Cluster**
   - TLS termination at gateway
   - Certificate validation (cert-manager)
   - Rate limiting (gateway configuration)
   - Authentication (Keycloak OIDC)

2. **Cluster → Services**
   - Service mesh mTLS (Istio - optional)
   - Network policies (NOT IMPLEMENTED)
   - RBAC (configured per service)

3. **Services → Data**
   - RBAC for Kubernetes resources
   - Database authentication
   - Storage encryption (Longhorn)

4. **GitOps → Cluster**
   - SSH deploy keys (read-only)
   - SOPS encryption for secrets
   - Age key stored in cluster

5. **Operators → Cluster**
   - Keycloak OIDC authentication
   - RBAC for authorization
   - Audit logging (API server)

### Secret Management

**At Rest:**
- Secrets encrypted with SOPS in Git
- Age asymmetric encryption
- Private keys stored securely outside Git

**In Transit:**
- TLS for all external communication
- mTLS for service-to-service (Istio - optional)
- Encrypted Git access (SSH)

**In Use:**
- Kubernetes Secrets (base64 encoded)
- RBAC restricts secret access
- Secrets mounted as volumes or environment variables

---

## Scalability Considerations

### Horizontal Scaling

**FluxCD Controllers:**
- Single replica by default
- Can be scaled for high-availability
- Leader election for multi-replica

**Platform Services:**
- Most services support horizontal scaling
- Configured via Helm values `replicaCount`
- Pod anti-affinity for distribution

**Observability:**
- Prometheus: Sharding for large clusters
- Loki: Horizontal scaling with object storage
- Tempo: Horizontal scaling with object storage

### Vertical Scaling

**Resource Limits:**
- Defined in Helm values
- Adjusted per cluster via override values
- Monitored via Prometheus metrics

**Storage:**
- Longhorn: Distributed storage, scales with nodes
- vSphere CSI: Scales with vSphere capacity
- OpenStack CSI: Scales with OpenStack capacity

---

## High Availability

### Control Plane

- 3 control plane nodes (recommended)
- etcd distributed across nodes
- API server load balanced

### Platform Services

**Critical Services (HA required):**
- cert-manager: 3 replicas
- kyverno: 3 replicas
- keycloak: 3 replicas
- prometheus: 2 replicas

**Storage:**
- Longhorn: 3 replicas per volume
- Velero: Backup to object storage

**Networking:**
- MetalLB: Speaker on every node
- Gateway: Multiple replicas

### Failure Modes

**Node Failure:**
- Pods rescheduled to healthy nodes
- Longhorn rebuilds replicas
- MetalLB announces from different node

**Zone Failure:**
- Requires multi-zone deployment
- Pod anti-affinity across zones
- Storage replication across zones

**Cluster Failure:**
- Velero backup/restore to new cluster
- GitOps repository unchanged
- Re-bootstrap FluxCD

---

## Multi-Cloud Support

### Provider Abstraction

**Storage:**
- Longhorn: Provider-agnostic
- vSphere CSI: VMware vSphere
- OpenStack CSI: OpenStack Cinder

**Networking:**
- MetalLB: Bare-metal, on-prem
- Cloud load balancers: AWS, GCP, Azure

**Compute:**
- Kubespray: Provisions on any infrastructure
- OpenTofu: Infrastructure as code

### Provider-Specific Services

**vSphere:**
- vSphere CSI driver
- vSphere cloud controller manager

**OpenStack:**
- OpenStack Cinder CSI
- OpenStack cloud controller manager
- OpenStack load balancer

---

## Operational Model

### Day 1: Cluster Bootstrap

1. Provision infrastructure (OpenTofu)
2. Deploy Kubernetes (Kubespray)
3. Bootstrap FluxCD
4. Create SOPS age key
5. Configure GitRepository sources
6. FluxCD deploys platform services

### Day 2: Service Management

1. Add/update service in Git
2. FluxCD detects change
3. FluxCD reconciles cluster state
4. Monitor via Grafana dashboards
5. Respond to alerts

### Day N: Upgrades

1. Update Helm chart version in Git
2. Update Helm values if needed
3. FluxCD performs rolling upgrade
4. Monitor upgrade progress
5. Rollback if issues detected

---

## Design Trade-offs

### GitOps Benefits

✅ **Pros:**
- Single source of truth (Git)
- Complete audit trail
- Declarative configuration
- Automated reconciliation
- Drift detection and correction

❌ **Cons:**
- Reconciliation delay (5-15 minutes)
- Requires Git expertise
- Debugging more complex
- Emergency changes slower

### HelmRelease Benefits

✅ **Pros:**
- Leverage Helm ecosystem
- Standardized deployment
- Values management
- Rollback capabilities

❌ **Cons:**
- Requires Helm charts
- Complex values merging
- FluxCD-specific knowledge

### SOPS Benefits

✅ **Pros:**
- Git-safe secrets
- Offline decryption
- Selective encryption
- FluxCD integration

❌ **Cons:**
- Key management burden
- Manual key rotation
- Key loss = data loss

---

## Future Architecture Evolution

### Planned Improvements

1. **Network Policies** - Implement default-deny policies
2. **Pod Security Admission** - Enforce Pod Security Standards
3. **Kyverno Policies** - Deploy validation, mutation, generation policies
4. **Automated Testing** - CI/CD pipeline with validation
5. **Dashboards as Code** - Version-controlled Grafana dashboards
6. **SLO Definitions** - Service-level objectives and alerts
7. **Image Scanning** - Automated vulnerability scanning
8. **Signature Verification** - Cosign image signature verification

### Architectural Considerations

1. **Multi-Tenancy** - Namespace isolation, resource quotas
2. **Service Mesh** - Full Istio deployment with mTLS
3. **Zero Trust** - Network policies, mTLS, RBAC
4. **Observability** - Distributed tracing, SLOs, runbooks
5. **Disaster Recovery** - Multi-cluster, cross-region backups

---

## Source Material

**Source Files:**
- [README.md](../../README.md)
- [docs/service-standards-and-lifecycle.md](../service-standards-and-lifecycle.md)
- [docs/explanation/enterprise-components.md](enterprise-components.md)
- [docs/reference/directory-structure.md](../reference/directory-structure.md)
- [applications/base/services/](../../applications/base/services/)
- [applications/base/managed-services/](../../applications/base/managed-services/)
- [iac/](../../iac/)
