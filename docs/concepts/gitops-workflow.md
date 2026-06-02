---
id: gitops-workflow
sidebar_label: GitOps Workflow
description: Explains the current FluxCD GitOps workflow in openCenter, including cluster-repo activation, source selection, and service reconciliation patterns.
doc_type: explanation
title: "GitOps Workflow in openCenter"
audience: "platform engineers, architects"
tags: [gitops, fluxcd, reconciliation, workflow]
---

# GitOps Workflow in openCenter

**Purpose:** For platform engineers and architects, explains how GitOps works in the current openCenter architecture, including repository roles, Flux reconciliation flow, deployment-model differences, drift correction, and remediation behavior.

## What GitOps Means Here

GitOps in openCenter does not mean that `openCenter-gitops-base` directly deploys itself into a cluster.

The current model is:

- `openCenter-gitops-base` provides reusable service installation content
- the private enterprise repo may import that base content and add enterprise-only deltas
- the **cluster overlay repo** creates the Flux objects that decide what is actually deployed into a specific cluster

So the cluster repo is the activation layer, and Flux is the reconciliation engine running inside the cluster.

## Repository Roles in the Workflow

The GitOps workflow spans three repository roles:

| Repository | Role in the workflow |
| --- | --- |
| `openCenter-gitops-base` | exports reusable base service paths and base values |
| `opencenter-gitops-enterprise` | imports base paths and applies enterprise-specific patches, sources, and values |
| Cluster overlay repo | defines Flux source and install objects, cluster-local overrides, secrets, and extra manifests |

This matters because a Git commit only affects a cluster if that cluster’s Flux configuration references the repo and path containing the changed content.

## The FluxCD Reconciliation Loop

FluxCD runs several controllers that coordinate through Kubernetes resources.

**Source Controller** fetches Git and chart content and stores the fetched artifact for the rest of Flux to consume.

**Kustomize Controller** builds and applies Kustomize paths, including plain manifests and service directories that create `HelmRelease` objects.

**Helm Controller** watches `HelmRelease` resources, fetches charts from their referenced sources, merges values, and installs or upgrades releases.

These controllers are independent, but the common flow is still:

```text
source object -> Kustomization -> rendered resources -> optional HelmRelease reconciliation
```

For Helm-based services, that usually becomes:

```text
GitRepository -> Kustomization -> HelmRelease -> chart install or upgrade
```

For manifest-only and staged services, the last step may instead be plain manifests or operator resources rather than a `HelmRelease`.

## Source Selection in the Current Architecture

The first GitOps decision happens in the cluster overlay repo: which source repo should Flux use for a service?

There are two supported patterns:

1. **Community deployment**
   The cluster repo points Flux directly at `openCenter-gitops-base//applications/base/services/<service>`.
2. **Enterprise deployment**
   The cluster repo points Flux at `opencenter-gitops-enterprise//applications/enterprise/services/<service>/overlays/install`, and that overlay imports the base service path from `openCenter-gitops-base`.

So the GitOps workflow begins in the cluster repo, not in this repository alone.

## Source -> Kustomization -> Deployment Flow

The typical flow for a Helm-based service looks like this.

### 1. Cluster Repo Defines the Source

The cluster overlay repo creates a Flux source object for the selected repository and ref.

Example pattern:

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

In community deployments, this source usually references `openCenter-gitops-base`.

In enterprise deployments, the source instead references the private enterprise repo, whose install overlay imports the base service.

The important point is that the source object belongs to the **cluster repo**, because the cluster repo owns deployment intent.

### 2. Cluster Repo Defines the Install Kustomization

The cluster repo then creates a Flux `Kustomization` pointing at the chosen service path.

Example pattern:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: opencenter-cert-manager
  path: ./applications/base/services/cert-manager
  prune: true
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2
      kind: HelmRelease
      name: cert-manager
      namespace: cert-manager
```

For enterprise deployments, the path would usually point to the enterprise install overlay instead.

This `Kustomization` is what causes Flux to apply the service path into the cluster.

### 3. The Applied Path Creates the Service Resources

What gets created depends on the service model.

For a standard Helm-based service such as `cert-manager`, the path in this repo creates:

- a namespace
- a chart source such as a `HelmRepository`
- a `HelmRelease`
- a base values Secret generated by Kustomize

For `cert-manager`, the base service `kustomization.yaml` generates the base values Secret:

```yaml
secretGenerator:
  - name: cert-manager-values-base
    namespace: cert-manager
    files:
      - values.yaml=helm-values/values-v1.18.2.yaml
```

The service `HelmRelease` then consumes both base and optional override values:

```yaml
spec:
  valuesFrom:
    - kind: Secret
      name: cert-manager-values-base
      valuesKey: values.yaml
    - kind: Secret
      name: cert-manager-values-override
      valuesKey: override.yaml
      optional: true
```

### 4. Helm Controller Reconciles the Release

When the `HelmRelease` exists, the Helm controller fetches the chart, merges referenced values, and performs install or upgrade actions.

The current base pattern commonly includes:

- `interval: 5m`
- `driftDetection.mode: enabled`
- install remediation retries
- conservative upgrade remediation
- optional override values supplied by the consuming cluster repo

## Not Every Service Follows the HelmRelease Path

One of the key points in the current architecture is that the GitOps workflow is not limited to Helm-based services.

### Manifest-Only Services

Some services are applied directly as manifests through Kustomize.

Examples in this repo include:

- `external-snapshotter`
- `olm`

For example, `external-snapshotter` applies upstream CRDs and controller manifests directly from the upstream repository, and `olm` applies release manifests from upstream URLs.

In these cases, the flow is:

```text
GitRepository -> Kustomization -> manifests applied directly
```

There is no `HelmRelease` stage.

### Staged and Operator-Driven Services

Some services install in ordered stages instead of a single release.

Example: `keycloak`

Its service tree is split into:

- `00-postgres`
- `10-operator`
- `20-keycloak`
- `30-oidc-rbac`

The operator stage applies an `OperatorGroup` and `Subscription`, and the workload stage applies the Keycloak custom resource afterward.

That means the GitOps workflow for these services is better described as:

```text
GitRepository -> Kustomization -> staged manifests and operator resources
```

rather than as one direct Helm release chain.

## Reconciliation Order and Dependencies

Flux does not infer all ordering automatically. The workflow depends on explicit dependency management where needed.

Typical ordering concerns include:

- source objects must exist before install `Kustomization` objects that depend on them
- operator or CRD providers must be ready before dependent custom resources are applied
- cluster-local values or secrets may need to exist before a service can reconcile successfully

That is why cluster repos commonly use `dependsOn` relationships between Flux `Kustomization` objects.

In practice, the expected order is usually:

1. apply the source object
2. apply the install `Kustomization`
3. apply cluster-local overlays, overrides, secrets, and workload custom resources

## Drift Detection and Remediation

Drift happens when the live cluster state differs from the Git-declared state. Common causes include:

- direct `kubectl apply` or `kubectl edit`
- manual changes to Helm-managed resources
- controller behavior that mutates managed resources outside the expected configuration

Flux corrects drift in two ways.

**Periodic reconciliation** re-runs on the configured interval.

**Drift detection mode** on `HelmRelease` resources can trigger faster correction when managed resources change unexpectedly.

For example, the current `cert-manager` base release uses:

```yaml
driftDetection:
  mode: enabled
```

## Install and Upgrade Remediation

The current base Helm pattern uses different remediation behavior for install and upgrade.

For `cert-manager`, the release currently uses:

```yaml
install:
  remediation:
    retries: 3
    remediateLastFailure: true
upgrade:
  remediation:
    retries: 0
    remediateLastFailure: false
```

This means:

- install failures are retried because they are often transient
- upgrade failures are not retried automatically because they often need human review

That asymmetric policy is consistent with the broader openCenter service patterns.

## Why This Workflow Works

The current GitOps workflow works because it keeps responsibilities separate:

- the base repo owns reusable install content
- the enterprise repo owns private additive deltas
- the cluster repo owns deployment intent and local configuration
- Flux owns reconciliation inside the cluster

This gives the platform:

- reusable base service definitions
- clear ownership boundaries
- support for both community and enterprise delivery
- support for Helm-based, manifest-only, and staged operator-driven services
- continuous correction of configuration drift

## Trade-offs and Limitations

This workflow has real costs.

**Multi-repo indirection**  
Understanding final cluster state may require checking the cluster repo, the base repo, and sometimes the enterprise repo.

**Controller layering**  
Debugging often means following source status, `Kustomization` status, and then `HelmRelease` status.

**Reconciliation delay**  
Changes are not instant. Source refresh intervals and later reconciliation intervals add delay unless operators force reconciliation manually.

**Dependency sensitivity**  
Staged or operator-driven installs can fail if prerequisites such as CRDs, secrets, or source objects are not ready yet.

**Operational exceptions remain**  
Some tasks still do not fit GitOps cleanly, such as emergency fixes, one-time operational procedures, or external secret rotation workflows.

## When GitOps Does Not Fit Cleanly

GitOps is strong for declarative desired state, but it is not the right tool for every action.

Examples include:

- one-time migrations
- imperative recovery steps during outages
- node operations such as drain or cordon
- coordinated secret rotation with external systems

For those cases, openCenter still uses imperative operational procedures alongside GitOps-managed configuration.
