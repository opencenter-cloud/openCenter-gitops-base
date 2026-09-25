---
id: version-upgrade-guide
sidebar_label: Version Upgrade Guide
description: Shows how to upgrade service versions in openCenter-gitops-base and what enterprise follow-up may be required.
doc_type: how-to
title: "Service Version Upgrade Guide"
audience: "platform engineers"
tags: [upgrades, helm, versioning, services]
---

# Service Version Upgrade Guide

**Purpose:** For platform engineers, shows how to upgrade service versions in openCenter-gitops-base and where related enterprise follow-up work happens in the private enterprise repo.

## Overview

The base repository upgrade flow is intentionally simpler than the enterprise flow.

In `openCenter-gitops-base`, most Helm-based service upgrades mean updating:

- the base values file
- the `HelmRelease` chart version
- the base `kustomization.yaml` reference to the new values file

If the service also has enterprise-specific hardening or private artifact rewrites, those follow-up changes happen in the private enterprise repository after the base update is complete.

## Standard Helm Service Upgrade

### Files to Update

For a standard Helm service in this base repo, you usually update these files:

1. `applications/base/services/<service>/helm-values/<new-values-file>.yaml` - New base values (the repository uses both `values-<version>.yaml` and `values-v<version>.yaml` conventions)
2. `applications/base/services/<service>/kustomization.yaml` - Update secretGenerator filename
3. `applications/base/services/<service>/helmrelease.yaml` - Update chart version

If an enterprise variant exists, the corresponding enterprise repo may also need updates to:

4. enterprise hardened values
5. enterprise component references
6. private image or chart source alignment

### Step-by-Step Process

Run the commands below from the repository root. Each path is intentionally fully qualified so the values Secret generator and HelmRelease being changed are unambiguous.

#### Step 1: Obtain New Helm Values

```bash
# Add/update Helm repository
helm repo add <repo-name> <repo-url>
helm repo update

# Show available versions
helm search repo <chart-name> --versions

# Get default values for new version
helm show values <repo-name>/<chart-name> --version <new-version> > /tmp/default-values.yaml
```

#### Step 2: Create New Base Values File

```bash
# Copy previous version as starting point
cp applications/base/services/<service>/helm-values/<old-values-file>.yaml \
   applications/base/services/<service>/helm-values/<new-values-file>.yaml

# Review changes in default values
diff /tmp/default-values.yaml applications/base/services/<service>/helm-values/<old-values-file>.yaml

# Update new values file with any necessary changes
vim applications/base/services/<service>/helm-values/<new-values-file>.yaml
```

#### Step 3: Update Root Kustomization

```bash
# Edit kustomization.yaml
vim applications/base/services/<service>/kustomization.yaml
```

Update the secretGenerator filename:

```yaml
# Before
secretGenerator:
  - name: <service>-values-base
    namespace: <namespace>
    type: Opaque
    files:
      - values.yaml=helm-values/<old-values-file>.yaml  # Old version
    options:
      disableNameSuffixHash: true

# After
secretGenerator:
  - name: <service>-values-base
    namespace: <namespace>
    type: Opaque
    files:
      - values.yaml=helm-values/<new-values-file>.yaml  # New version
    options:
      disableNameSuffixHash: true
```

#### Step 4: Update HelmRelease Version

```bash
# Edit helmrelease.yaml
vim applications/base/services/<service>/helmrelease.yaml
```

Update the chart version:

```yaml
# Before
spec:
  chart:
    spec:
      chart: <chart-name>
      version: <old-version>  # Old version

# After
spec:
  chart:
    spec:
      chart: <chart-name>
      version: <new-version>  # New version
```

#### Step 5: Validate Changes

```bash
# Validate kustomization builds from the service directory
kubectl kustomize applications/base/services/<service>

# Check for syntax errors
kubectl apply --dry-run=client -f applications/base/services/<service>/helmrelease.yaml
```

#### Step 6: Test in Non-Production

```bash
# Commit only the reviewed service change
git add applications/base/services/<service>
git commit -m "Upgrade <service> from v<old> to v<new>"
git push

# Deploy to test cluster
flux reconcile source git <source-name> -n flux-system
flux reconcile kustomization <install-kustomization-name> -n flux-system --with-source

# Monitor deployment
kubectl get helmrelease <service> -n <namespace> -w
kubectl get pods -n <namespace>
```

#### Step 7: Verify Upgrade

```bash
# Check HelmRelease status
kubectl describe helmrelease <service> -n <namespace>

# Verify version
helm list -n <namespace>

# Check pod health
kubectl get pods -n <namespace>
kubectl logs -n <namespace> <pod-name>

# Verify functionality
# (service-specific verification steps)
```

#### Step 8: Deploy to Production

```bash
# After successful test cluster validation
# Deploy to production clusters following change management process
```

## Example: Service Upgrade (`v<old-version>` -> `v<new-version>`)

### Step 1: Obtain New Values

```bash
helm repo add <repo-name> <repo-url>
helm repo update
helm show values <repo-name>/<chart-name> --version <new-version> > /tmp/<chart-name>-<new-version>.yaml
```

### Step 2: Create New Base Values

```bash
cp applications/base/services/<service>/helm-values/<old-values-file>.yaml \
   applications/base/services/<service>/helm-values/<new-values-file>.yaml
diff /tmp/<chart-name>-<new-version>.yaml applications/base/services/<service>/helm-values/<old-values-file>.yaml
# Review differences and update applications/base/services/<service>/helm-values/<new-values-file>.yaml as needed
```

### Step 3: Update Root Kustomization

```yaml
# kustomization.yaml
secretGenerator:
  - name: <service>-values-base
    namespace: <namespace>
    type: Opaque
    files:
      - values.yaml=helm-values/<new-values-file>.yaml  # Updated
    options:
      disableNameSuffixHash: true
```

### Step 4: Update HelmRelease

```yaml
# helmrelease.yaml
spec:
  chart:
    spec:
      chart: <chart-name>
      version: <new-version>  # Updated
```

### Step 5: Validate and Deploy

```bash
kubectl kustomize applications/base/services/<service>
git add applications/base/services/<service>
git commit -m "Upgrade <service> from v<old-version> to v<new-version>"
git push
flux reconcile source git <source-name> -n flux-system
flux reconcile kustomization <install-kustomization-name> -n flux-system --with-source
```

### Enterprise Follow-Up

If the service also has an enterprise add-on in the private repo, follow up there after the base change:

- create or update the enterprise repo values file that matches the new base chart or app version
- update the enterprise component or overlay reference to that enterprise values file if needed
- verify mirrored image tags still match the base chart or app version
- validate the enterprise install overlay against the updated base ref

## Multi-Component Service Upgrade

For services with multiple sub-components (istio, observability, keycloak), upgrade each sub-component independently.

### Example: Istio Upgrade

```bash
# Upgrade istio/base
cd applications/base/services/istio/base
# Follow standard upgrade process

# Upgrade istio/istiod
cd applications/base/services/istio/istiod
# Follow standard upgrade process

# Update shared sources if needed
cd applications/base/services/istio/sources
vim istio.yaml  # Update HelmRepository if needed
```

## Non-Helm Service Upgrade

For services using raw manifests (like OLM), update the manifest URLs or versions.

### Example: OLM Upgrade

```yaml
# kustomization.yaml
resources:
  - "https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.35.0/crds.yaml"  # Updated
  - "https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.35.0/olm.yaml"   # Updated
```

## Breaking Changes Handling

### Identifying Breaking Changes

```bash
# Review upstream release notes
# Check for:
# - Deprecated APIs
# - Removed features
# - Configuration changes
# - CRD changes
# - Migration requirements
```

### Service-Specific CRD Policy and Staging

CRD changes are not ordinary application rollbacks. Preserve existing custom resources and never delete a CRD as an upgrade or rollback step. Use the service's owner and staging boundary rather than applying a vendor CRD URL directly.

| Service | Repository evidence | Upgrade/staging policy |
| --- | --- | --- |
| cert-manager | `applications/base/services/cert-manager/helm-values/values-v1.21.2.yaml` sets `crds.enabled: true` and `crds.keep: true`. | Let the HelmRelease own the CRDs. Review the base change, then reconcile the actual example install Kustomization `cert-manager-base -n flux-system`; do not create a second CRD Kustomization. |
| Keycloak | `applications/base/services/keycloak/10-operator/subscription.yaml` uses manual InstallPlan approval; the flow is `keycloak-operator` then `keycloak-cr`. | Review and approve the OLM InstallPlan in the operator stage first, wait for the CSV/CRDs, then reconcile the Keycloak CR stage. Do not apply or roll back operator CRDs independently. |
| OpenTelemetry Kube Stack | `applications/base/services/observability/opentelemetry-kube-stack/helm-values/values-0.23.0.yaml` enables `crds.installOtel` and `crds.installPrometheus`. | Keep CRDs chart-owned and stage the consumer's actual install Kustomization after the chart change is reviewed. Discover that Kustomization; do not invent a separate CRD object. |

### GitOps-Safe CRD Upgrade

Run from the repository root. Render for review, back up live state, commit and push the repository change, then reconcile the source and the install Kustomization. `kubectl kustomize` is for rendering; do not use `kubectl apply -k` to bypass GitOps for a normal upgrade.

```bash
# Render and review the service change.
kubectl kustomize applications/base/services/<service> \
  > /tmp/<service>-upgrade.yaml

# Back up the live CRD and custom resources before a schema change.
CRD_NAME="<crd-name>"
RESOURCE_KIND="<resource-kind>"
kubectl get crd "$CRD_NAME" -o yaml > "/tmp/${CRD_NAME}-before.yaml"
kubectl get "$RESOURCE_KIND" -A -o yaml > "/tmp/${RESOURCE_KIND}-before.yaml"

# Commit the reviewed service files using full repository paths.
git add applications/base/services/<service>
git commit -m "Upgrade <service> CRD and controller"
git push

# Reconcile the consumer source and its actual install Kustomization.
flux reconcile source git <source-name> -n flux-system
flux reconcile kustomization <install-kustomization-name> -n flux-system --with-source

# Confirm the CRD is Established and existing instances remain readable.
kubectl wait --for=condition=Established "crd/${CRD_NAME}" --timeout=5m
kubectl get "$RESOURCE_KIND" -A
```

For the checked-in cert-manager example, use source `opencenter-cert-manager` and install Kustomization `cert-manager-base -n flux-system`. If the schema is not backward-compatible, pause and follow the operator/chart migration procedure. Do not blindly revert the CRD schema or remove stored versions.

### Handling Configuration Changes

```bash
# If configuration structure changes:
# 1. Update helm-values files with new structure
# 2. Test in non-production
# 3. Document changes in commit message
# 4. Update service documentation
```

## Rollback Procedure

### If Upgrade Fails

```bash
# Revert the application/values change. Do not delete CRDs or custom resources.
git revert <commit-hash>
git push

# Force reconciliation
flux reconcile source git <source-name> -n flux-system
flux reconcile kustomization <install-kustomization-name> -n flux-system --with-source

# Verify rollback
kubectl get helmrelease <service> -n <namespace>
helm list -n <namespace>
```

### Manual Rollback

```bash
# If git revert doesn't work, manually restore only the service files.
# Do not restore or delete CRDs without a compatibility review.
git checkout <previous-commit> -- applications/base/services/<service>/

# Commit and push
git add applications/base/services/<service>
git commit -m "Rollback <service> to v<old-version>"
git push
flux reconcile source git <source-name> -n flux-system
flux reconcile kustomization <install-kustomization-name> -n flux-system --with-source
```

For the checked-in cert-manager example, the Flux install Kustomization is `cert-manager-base` in `flux-system`; verify the corresponding name before reconciling another service.

## Upgrade Checklist

### Pre-Upgrade

- [ ] Review upstream release notes
- [ ] Identify breaking changes
- [ ] Backup current configuration
- [ ] Test in non-production cluster
- [ ] Document upgrade plan
- [ ] Schedule maintenance window (if needed)
- [ ] Notify stakeholders

### During Upgrade

- [ ] Create new values files
- [ ] Update kustomization files
- [ ] Update helmrelease version
- [ ] Validate kustomization builds
- [ ] Commit changes with clear message
- [ ] Deploy to test cluster
- [ ] Verify functionality
- [ ] Monitor for issues

### Post-Upgrade

- [ ] Verify all pods running
- [ ] Check HelmRelease status
- [ ] Verify service functionality
- [ ] Monitor logs for errors
- [ ] Update documentation
- [ ] Notify stakeholders of completion
- [ ] Document lessons learned

## Common Issues

### Issue: Values File Not Found

**Symptom:** Error: "file not found: applications/base/services/<service>/helm-values/<values-file>.yaml"

**Solution:**
```bash
# Verify file exists
ls -la applications/base/services/<service>/helm-values/

# Check kustomization.yaml references correct filename
grep "values.yaml" applications/base/services/<service>/kustomization.yaml
```

### Issue: HelmRelease Fails to Upgrade

**Symptom:** HelmRelease stuck in "upgrading" state

**Solution:**
```bash
# Check HelmRelease status
kubectl describe helmrelease <service> -n <namespace>

# Check helm-controller logs
kubectl logs -n flux-system deploy/helm-controller

# Force reconciliation
flux reconcile helmrelease <service> -n <namespace> --with-source
```

### Issue: CRD Version Mismatch

**Symptom:** Error: "CRD version mismatch" or "unknown field"

**Solution:**
```bash
# Do not delete or apply an unreviewed CRD manifest. Commit the reviewed
# service path, push it, then reconcile the actual install Kustomization.
git add applications/base/services/<service>
git commit -m "Upgrade <service> CRD and controller"
git push
flux reconcile source git <source-name> -n flux-system
flux reconcile kustomization <install-kustomization-name> -n flux-system --with-source
```

### Issue: Breaking Configuration Changes

**Symptom:** Service fails to start after upgrade

**Solution:**
```bash
# Review upstream migration guide
# Update values files with new configuration structure
# Test in non-production first
# If needed, rollback and plan migration
```

## Best Practices

1. **Always test in non-production first** - Never upgrade production directly
2. **Review release notes** - Understand what's changing
3. **Backup configurations** - Keep previous versions for rollback
4. **Use semantic versioning** - Understand major/minor/patch implications
5. **Document changes** - Clear commit messages and documentation updates
6. **Monitor after upgrade** - Watch for issues in first 24 hours
7. **Staged rollout** - Upgrade one cluster at a time
8. **Maintain version consistency** - Keep all clusters on same version when possible

## Automation Opportunities

### Version Upgrade Script

```bash
#!/bin/bash
# upgrade-service.sh

SERVICE="$1"
OLD_VERSION="$2"
NEW_VERSION="$3"

# This helper assumes the service uses values-v<version>.yaml and
# version: v<version>. Services with values-<version>.yaml or another
# filename convention must be upgraded manually after inspecting their files.

if [[ -z "$SERVICE" ]] || [[ -z "$OLD_VERSION" ]] || [[ -z "$NEW_VERSION" ]]; then
    echo "Usage: $0 <service> <old-version> <new-version>"
    exit 1
fi

SERVICE_DIR="applications/base/services/$SERVICE"

# Create new values files
cp "$SERVICE_DIR/helm-values/values-v$OLD_VERSION.yaml" \
   "$SERVICE_DIR/helm-values/values-v$NEW_VERSION.yaml"

# Update kustomization.yaml
sed -i.bak "s/values-v$OLD_VERSION.yaml/values-v$NEW_VERSION.yaml/g" \
    "$SERVICE_DIR/kustomization.yaml"

# Update helmrelease.yaml
sed -i.bak "s/version: v$OLD_VERSION/version: v$NEW_VERSION/g" \
    "$SERVICE_DIR/helmrelease.yaml"

# Cleanup backup files
rm -f "$SERVICE_DIR"/*.bak

echo "Upgraded $SERVICE from v$OLD_VERSION to v$NEW_VERSION"
echo "Please review base repo changes and test before committing"
```

## References

- [Directory Structure Reference](../reference/directory-structure.md)
- [Enterprise Components Pattern](../concepts/enterprise-components.md)
- [FluxCD HelmRelease Documentation](https://fluxcd.io/flux/components/helm/helmreleases/)
- [Helm Documentation](https://helm.sh/docs/)
