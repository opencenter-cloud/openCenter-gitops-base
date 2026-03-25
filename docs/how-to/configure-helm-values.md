---
id: configure-helm-values
sidebar_label: Configure Helm Values
description: Shows how to combine base Helm values from this repo with cluster-specific override values from consuming repositories.
doc_type: how-to
title: "Configure Helm Values"
audience: "platform engineers"
tags: [helm, values, overrides, configuration]
---

# Configure Helm Values

**Purpose:** For platform engineers, shows how to customize Helm-based services by combining base values from this repository with optional override values supplied by the consuming repository.

## Prerequisites

- Service already exists in `openCenter-gitops-base`
- Access to the repository that deploys the service to a cluster
- Familiarity with Flux `HelmRelease.valuesFrom`

## Base Repo Model

For Helm-based services in this repo, the normal pattern is:

1. **Base values** in `applications/base/services/<service>/helm-values/values-<version>.yaml`
2. **Base Secret generation** in the service `kustomization.yaml`
3. **Optional override Secret reference** in the service `helmrelease.yaml`

The base repo owns the baseline. The consuming cluster repo owns cluster-specific overrides.

If a private enterprise repo is used, that repo can add an additional enterprise-specific values source or patch the upstream chart/image source, but that behavior is outside this base repo.

## Step 1: Inspect the Base Values

Check the values currently shipped by the base service:

```bash
sed -n '1,200p' applications/base/services/<service>/helm-values/values-v<chart-version>.yaml
```

Also check how the service consumes them:

```bash
sed -n '1,200p' applications/base/services/cert-manager/kustomization.yaml
sed -n '1,220p' applications/base/services/cert-manager/helmrelease.yaml
```

You should typically see:

- a generated `cert-manager-values-base` Secret
- an optional `cert-manager-values-override` entry in `valuesFrom`

## Step 2: Decide Whether the Change Belongs in Base or Override

Use **base values** when the setting should apply to all consumers of this repo:

- hardened defaults
- common resource baselines
- common monitoring settings
- chart-wide safe defaults

Use **override values** when the setting varies by cluster or environment:

- domain names
- storage classes
- replica counts
- node selectors and tolerations
- ingress hosts
- external endpoints or environment-specific integration values

## Step 3: Update Base Values When the Default Should Change

Edit the versioned base values file:

```yaml
# applications/base/services/<service>/helm-values/values-v<chart-version>.yaml
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 50m
    memory: 64Mi

prometheus:
  enabled: true
  servicemonitor:
    enabled: true
    interval: 30s
```

This is the right place for settings that should travel with the base service everywhere it is consumed.

## Step 4: Create Cluster-Specific Override Values

In the consuming cluster repo, create an override file such as:

```yaml
# override-values.yaml
replicaCount: 3

extraArgs:
  - --dns01-recursive-nameservers=192.168.1.1:53
  - --dns01-recursive-nameservers-only

ingress:
  host: cert-manager.cluster.example.com
```

Generate the Secret that the base `HelmRelease` already expects:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

secretGenerator:
  - name: cert-manager-values-override
    namespace: cert-manager
    files:
      - override.yaml=override-values.yaml
    options:
      disableNameSuffixHash: true
```

The important point is that the override Secret name must match the `valuesFrom` entry in the base service.

## Step 5: Validate the Effective Configuration

Render the consuming overlay:

```bash
kustomize build .
```

Dry-run the apply when appropriate:

```bash
kustomize build . | kubectl apply --dry-run=client -f -
```

After reconciliation, inspect the `HelmRelease`:

```bash
kubectl get helmrelease cert-manager -n cert-manager -o yaml
kubectl get helmrelease cert-manager -n cert-manager -o jsonpath='{.spec.valuesFrom[*].name}'
```

Typical output:

```text
cert-manager-values-base cert-manager-values-override
```

## Step 6: Reconcile

If you need to trigger an immediate reconcile:

```bash
flux reconcile kustomization cert-manager -n flux-system
flux reconcile helmrelease cert-manager -n cert-manager --with-source
```

## Common Patterns

### Resource Tuning in Overrides

Use overrides for environment-specific sizing:

```yaml
resources:
  requests:
    cpu: 500m
    memory: 512Mi
```

### Storage Class Selection

Use overrides for cluster storage differences:

```yaml
persistence:
  storageClass: longhorn
```

### Hostnames and Ingress

Use overrides for cluster-specific DNS:

```yaml
ingress:
  enabled: true
  hosts:
    - app.example.com
```

## Enterprise Repo Note

When a private enterprise repo consumes this base, it may also:

- patch chart sources to private registries or repositories
- add enterprise-only values
- replace image references

That is a consumer-repo concern, not a standard file layout inside `openCenter-gitops-base`.

## Best Practices

- keep base values small, durable, and shared
- keep override files focused on true cluster differences
- avoid copying large parts of the base file into overrides
- align values filenames with the chart version in the `HelmRelease`
- validate rendered manifests before pushing changes

## Related References

- [Helm Values Schema](../reference/helm-values-schema.md)
- [Kustomize Patterns](../reference/kustomize-patterns.md)
- [Enterprise Components](../explanation/enterprise-components.md)
