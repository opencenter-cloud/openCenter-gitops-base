---
id: flux-resources
title: "FluxCD Resources Reference"
sidebar_label: Flux Resources
description: Reference for the FluxCD resource patterns used by openCenter cluster repositories when consuming openCenter-gitops-base.
doc_type: reference
audience: "platform engineers"
tags: [fluxcd, gitops, kubernetes, resources]
---

# FluxCD Resources Reference

**Type:** Reference  
**Audience:** Platform engineers  
**Last Updated:** 2026-04-01

This document is a field-oriented reference for the main FluxCD resources used in the current openCenter delivery model.

It does not try to re-explain the full GitOps workflow. For that, use [GitOps Workflow](../explanation/gitops-workflow.md).

In the current architecture:

- `openCenter-gitops-base` exports reusable install paths
- cluster overlay repos create the Flux objects that point at those paths
- Flux controllers in the cluster reconcile the selected sources and paths

---

## GitRepository

Defines a Git source artifact for Flux.

### Specification

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: opencenter-cert-manager
  namespace: flux-system
spec:
  interval: 15m
  url: https://github.com/opencenter-cloud/openCenter-gitops-base
  ref:
    tag: <release-tag>
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `interval` | duration | Yes | Sync interval (e.g., `15m`, `1h`) |
| `url` | string | Yes | Git repository URL (SSH or HTTPS) |
| `ref.tag` | string | No | Git tag to track |
| `ref.branch` | string | No | Git branch to track |
| `ref.commit` | string | No | Specific commit SHA |
| `secretRef.name` | string | No | Secret containing SSH key or credentials |

### Common Ref Patterns

**Tag-based (recommended for stability):**
```yaml
ref:
  tag: <release-tag>
```

**Branch-based (for development):**
```yaml
ref:
  branch: main
```

**Commit-based (for pinning):**
```yaml
ref:
  commit: abc123def456
```

---

## HelmRepository

Defines a Helm chart source used by a `HelmRelease`.

### Specification

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: jetstack
  namespace: cert-manager
spec:
  interval: 1h
  url: https://charts.jetstack.io
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `interval` | duration | Yes | Sync interval |
| `url` | string | Yes | Helm repository URL |
| `secretRef.name` | string | No | Secret for authentication |

---

## HelmRelease

Manages Helm chart installations and upgrades.

### Specification

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  interval: 5m
  timeout: 10m
  chart:
    spec:
      chart: cert-manager
      version: v1.18.2
      sourceRef:
        kind: HelmRepository
        name: jetstack
        namespace: cert-manager
  driftDetection:
    mode: enabled
  install:
    remediation:
      retries: 3
      remediateLastFailure: true
  upgrade:
    remediation:
      retries: 0
      remediateLastFailure: false
  valuesFrom:
    - kind: Secret
      name: cert-manager-values-base
      valuesKey: values.yaml
    - kind: Secret
      name: cert-manager-values-override
      valuesKey: override.yaml
      optional: true
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `interval` | duration | Yes | Reconciliation interval (typically `5m`) |
| `timeout` | duration | Yes | Operation timeout (typically `10m`) |
| `driftDetection.mode` | string | No | `enabled` or `disabled` (default: disabled) |
| `chart.spec.chart` | string | Yes | Helm chart name |
| `chart.spec.version` | string | Yes | Chart version |
| `chart.spec.sourceRef` | object | Yes | Reference to HelmRepository or GitRepository |
| `install.remediation.retries` | int | No | Install retry count (default: 3) |
| `install.remediation.remediateLastFailure` | bool | No | Retry last failure (default: true) |
| `upgrade.remediation.retries` | int | No | Upgrade retry count (default: 0) |
| `upgrade.remediation.remediateLastFailure` | bool | No | Retry last upgrade failure (default: false) |
| `valuesFrom` | array | No | List of value sources (Secrets or ConfigMaps) |

### Drift Detection

When enabled, Flux detects configuration drift and automatically corrects it:

```yaml
driftDetection:
  mode: enabled
```

### Remediation Policies

**Install remediation** (aggressive):
- Retries: 3
- Remediate last failure: true
- Use case: New installations should retry automatically

**Upgrade remediation** (conservative):
- Retries: 0
- Remediate last failure: false
- Use case: Failed upgrades require manual intervention

---

## Kustomization

Applies a selected repository path to the cluster.

### Specification

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  interval: 5m
  retryInterval: 1m
  timeout: 10m
  sourceRef:
    kind: GitRepository
    name: opencenter-cert-manager
    namespace: flux-system
  path: applications/base/services/cert-manager
  prune: true
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2
      kind: HelmRelease
      name: cert-manager
      namespace: cert-manager
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dependsOn` | array | No | List of Kustomizations to wait for |
| `interval` | duration | Yes | Reconciliation interval |
| `retryInterval` | duration | No | Retry interval on failure |
| `timeout` | duration | Yes | Operation timeout |
| `sourceRef` | object | Yes | Reference to GitRepository |
| `path` | string | Yes | Path within repository |
| `prune` | bool | No | Delete resources removed from Git (default: false) |
| `healthChecks` | array | No | Resources to check before marking ready |

### Dependencies

Use `dependsOn` to create ordered deployments:

```yaml
spec:
  dependsOn:
    - name: cert-manager
      namespace: flux-system
```

This is commonly used in cluster repos to order source, install, and follow-on workload paths.

### Health Checks

Verify resource health before marking Kustomization as ready:

```yaml
healthChecks:
  - apiVersion: apps/v1
    kind: Deployment
    name: cert-manager
    namespace: cert-manager
  - apiVersion: helm.toolkit.fluxcd.io/v2
    kind: HelmRelease
    name: cert-manager
    namespace: cert-manager
```

## Reconciliation Intervals

Common intervals used in this model:

| Resource Type | Interval | Rationale |
|---------------|----------|-----------|
| GitRepository | `15m` | Common cluster-repo source polling interval |
| HelmRepository | `1h` | Common chart source polling interval |
| HelmRelease | `5m` | Common service reconciliation interval |
| Kustomization | `5m` | Common install reconciliation interval |

---

## Flux CLI Commands

### Reconcile

Force immediate reconciliation:

```bash
# Reconcile specific resource
flux reconcile source git opencenter-cert-manager
flux reconcile helmrelease cert-manager -n cert-manager
flux reconcile kustomization cert-manager

# Reconcile with source
flux reconcile kustomization cert-manager --with-source
```

### Get Status

```bash
# All resources
flux get all -A

# Specific resource type
flux get sources git
flux get helmreleases -A
flux get kustomizations
```

### Logs

```bash
# Controller logs
flux logs --level=error --all-namespaces

# Specific resource
flux logs --kind=HelmRelease --name=cert-manager --namespace=cert-manager
```

### Suspend/Resume

```bash
# Suspend reconciliation
flux suspend helmrelease cert-manager -n cert-manager

# Resume reconciliation
flux resume helmrelease cert-manager -n cert-manager
```

## Troubleshooting

### Check Resource Status

```bash
flux get sources git opencenter-cert-manager
flux get helmreleases -n cert-manager
flux get kustomizations
```

### View Events

```bash
kubectl describe gitrepository opencenter-cert-manager -n flux-system
kubectl describe helmrelease cert-manager -n cert-manager
kubectl describe kustomization cert-manager -n flux-system
```

### Force Reconciliation

```bash
flux reconcile source git opencenter-cert-manager
flux reconcile helmrelease cert-manager -n cert-manager --with-source
```

### View Controller Logs

```bash
kubectl logs -n flux-system deploy/source-controller
kubectl logs -n flux-system deploy/helm-controller
kubectl logs -n flux-system deploy/kustomize-controller
```
