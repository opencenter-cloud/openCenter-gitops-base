---
id: helm-service-onboarding
sidebar_label: Helm Service Onboarding
description: Step-by-step guide for onboarding Helm-based services from the community or enterprise repo into a cluster overlay repo.
doc_type: how-to
title: "Helm Service Onboarding"
audience: "platform engineers, cluster operators"
tags: [helmrelease, overlays, fluxcd, onboarding]
---

# Helm Service Onboarding

**Purpose:** For platform engineers and cluster operators, explains how to onboard a Helm-based service into a cluster overlay repo. Use this guide for services such as `cert-manager`, `harbor`, `longhorn`, `metallb`, `loki`, and other Helm-based platform services.

## When To Use This Guide

Use this guide when the base service is deployed with:

- `HelmRelease`
- `HelmRepository` or OCI `HelmRepository`
- Base values under `helm-values/`

If the service is installed through OLM, use [OLM Service Onboarding](olm-service-onboarding.md) instead.

If the operator is installed with Helm and the cluster overlay repo must create custom resources such as `Kafka` or `postgresql`, use [Operator CR Service Onboarding](operator-cr-service-onboarding.md) instead.

---

## Workflow Summary

The path examples below use a common cluster-repo layout where service activation lives under `applications/overlays/<cluster>/services/`. If your cluster repository uses a different root, keep the same separation between `sources/`, `fluxcd/`, and `services/<service>/` in the equivalent location.

1. Decide whether the cluster should consume the community repo or the enterprise repo
2. Inspect the base service `HelmRelease` to understand how overrides are accepted
3. Create the cluster overlay directory structure for the service
4. Add the Flux source object in `services/sources/`
5. Add the install `Kustomization` in `services/fluxcd/`
6. Add cluster-local values, secrets, and manifests in `services/<service>/`
7. Validate Flux reconciliation and the resulting workload

For the community versus enterprise source pattern, use [Service Deployment Patterns](service-deployment-patterns.md).

---

## Step 1: Inspect The Base Service

Before onboarding, check the service under:

```text
applications/base/services/<service>/
```

Confirm:

- The service is installed with `HelmRelease`
- The namespace used by the service
- The chart source object and repository type
- Whether the `HelmRelease` uses `valuesFrom`
- The Secret names and key names expected by `valuesFrom`

Do not assume every Helm service follows the exact `cert-manager` pattern. Some services may use different Secret names, different keys, or a different values layout.

---

## Step 2: Create The Cluster Overlay Structure

Create the service structure in the **cluster overlay repo**. In the common layout used in these examples:

```text
applications/overlays/<cluster>/services/
├── sources/
│   ├── kustomization.yaml
│   └── opencenter-<service>-community.yaml
├── fluxcd/
│   ├── kustomization.yaml
│   └── <service>.yaml
└── <service>/
    ├── kustomization.yaml
    ├── helm-values/override-values.yaml
    └── cluster-specific secrets or manifests
```

If the service is sourced from the enterprise repo, replace the source file name with:

```text
opencenter-<service>-enterprise.yaml
```

---

## Step 3: Add The Flux Source

Create the `GitRepository` in the directory that holds shared source objects. In the common layout used in these examples:

```text
applications/overlays/<cluster>/services/sources/
```

Then register it from the matching `kustomization.yaml`:

```text
applications/overlays/<cluster>/services/sources/kustomization.yaml
```

Typical source naming:

- Community: `opencenter-<service>-community`
- Enterprise: `opencenter-<service>-enterprise`

For private enterprise sourcing, the cluster repo also needs:

- `enterprise-repo` for Git access
- `oci-creds` for private OCI charts, when used
- `registry-credentials` for private image pulls, when used

Store sensitive values with SOPS. See [Manage Secrets with SOPS](manage-secrets.md) and [SOPS Configuration](../reference/sops-configuration.md).

---

## Step 4: Add The Install Kustomization

Create the install object in the directory that holds Flux activation objects. In the common layout used in these examples:

```text
applications/overlays/<cluster>/services/fluxcd/<service>.yaml
```

Then register it from the matching `kustomization.yaml`:

```text
applications/overlays/<cluster>/services/fluxcd/kustomization.yaml
```

If `fluxcd/kustomization.yaml` does not include `<service>.yaml`, Flux will not apply the service install `Kustomization`.

This object should:

- Point to the correct `GitRepository`
- Use the correct path for the selected source repo
- Target the correct namespace
- Declare `dependsOn` when the service requires source ordering

Typical service paths:

- Community: `./applications/base/services/<service>`
- Enterprise: `./applications/enterprise/services/<service>/overlays/install`

---

## Step 5: Add Cluster-Local Overrides

Create the cluster-local overlay in the directory that holds service-specific overlay content. In the common layout used in these examples:

```text
applications/overlays/<cluster>/services/<service>/
```

Typical cluster-local content includes:

- Override values rendered into a Secret
- Issuers, ingress, routes, or certificates
- Storage class changes
- Environment-specific credentials
- Additional labels, annotations, or policies

If the service `HelmRelease` uses `valuesFrom`, create the matching Secret or generator in the cluster overlay.

The cluster overlay can also contain additional manifests, Secrets, or service-specific resources. For example, `cert-manager` commonly needs cluster-local resources such as a `ClusterIssuer` manifest in addition to Helm values.

---

## Cert-Manager Example

`cert-manager` is a good example of the standard Helm onboarding flow because the base service exposes:

- A `HelmRelease`
- Base values from `cert-manager-values-base`
- Optional cluster-local overrides from `cert-manager-values-override`

One real cluster pattern uses a service source plus a separate override reconciliation. For a community-based example, the cluster repo can define:

Example `sources/opencenter-cert-manager-community.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: opencenter-cert-manager-community
  namespace: flux-system
spec:
  interval: 15m
  url: https://github.com/opencenter-cloud/openCenter-gitops-base
  ref:
    tag: <release-tag>
```

Example `sources/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./opencenter-cert-manager-community.yaml
```

Example `fluxcd/cert-manager.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager-base
  namespace: flux-system
spec:
  dependsOn:
    - name: sources
      namespace: flux-system
  interval: 15m
  retryInterval: 1m
  timeout: 10m
  sourceRef:
    kind: GitRepository
    name: opencenter-cert-manager-community
    namespace: flux-system
  path: ./applications/base/services/cert-manager
  targetNamespace: cert-manager
  prune: true
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2
      kind: HelmRelease
      name: cert-manager
      namespace: cert-manager
  commonMetadata:
    labels:
      app.kubernetes.io/part-of: cert-manager
      app.kubernetes.io/managed-by: flux
      opencenter/managed-by: opencenter
```

This `Kustomization` activates the selected install path. In this example it points directly at the community base service.

Example override `Kustomization` in the same `fluxcd/cert-manager.yaml` file:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager-override
  namespace: flux-system
spec:
  dependsOn:
    - name: sources
      namespace: flux-system
  interval: 15m
  retryInterval: 1m
  timeout: 10m
  decryption:
    provider: sops
    secretRef:
      name: sops-age
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  path: ./applications/overlays/<cluster>/services/cert-manager
  targetNamespace: cert-manager
  prune: true
  wait: true
  commonMetadata:
    labels:
      app.kubernetes.io/part-of: cert-manager
      app.kubernetes.io/managed-by: flux
      opencenter/managed-by: opencenter
```

This second `Kustomization` reconciles the cluster-local override Secret and supporting manifests such as issuers or certificates from the cluster repo.

Example `fluxcd/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./cert-manager.yaml
```

The source file points Flux at the selected repo, and the `fluxcd/cert-manager.yaml` file defines both the install `Kustomization` and the cluster-local override `Kustomization`.

Example `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: cert-manager

resources:
  - letsencrypt-issuer.yaml

secretGenerator:
  - name: cert-manager-values-override
    files:
      - override.yaml=helm-values/override-values.yaml
    options:
      disableNameSuffixHash: true
```

Example `helm-values/override-values.yaml`:

```yaml
replicaCount: 3
prometheus:
  enabled: true
```

Example `letsencrypt-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: platform@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

For service-specific guidance, see [Cert-manager Configuration Guide](services/cert-manager.md).

---

## Updating Existing Helm Service Configuration

For an existing Helm-based deployment, update the required cluster-overlay-managed content in the **cluster overlay repo**:

- Update `services/<service>/helm-values/override-values.yaml` for Helm value changes
- Update any existing resource manifest managed from the cluster overlay
- Add or update any required Secret or supporting manifest
- Commit and push the cluster repo change

Do not edit the community or enterprise repo as part of a normal cluster change.

If a shared baseline change is required, raise an issue in the relevant repository instead.

---

## Validation

Check:

```bash
flux get sources git -n flux-system
flux get kustomizations -n flux-system
kubectl get helmreleases -A
kubectl get pods -n <namespace>
```

For a parameter change, inspect the live workload:

```bash
kubectl get deploy -n <namespace> <deployment-name> -o yaml
```

---

## Related Docs

- [Service Deployment Patterns](service-deployment-patterns.md)
- [OLM Service Onboarding](olm-service-onboarding.md)
- [Operator CR Service Onboarding](operator-cr-service-onboarding.md)
- [Configure Helm Values](configure-helm-values.md)
- [Manage Secrets with SOPS](manage-secrets.md)
