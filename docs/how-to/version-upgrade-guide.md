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

1. `helm-values/values-v<new-version>.yaml` - New base values
2. `kustomization.yaml` - Update secretGenerator filename
3. `helmrelease.yaml` - Update chart version

If an enterprise variant exists, the corresponding enterprise repo may also need updates to:

4. enterprise hardened values
5. enterprise component references
6. private image or chart source alignment

### Step-by-Step Process

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
cp helm-values/values-v<old-version>.yaml helm-values/values-v<new-version>.yaml

# Review changes in default values
diff /tmp/default-values.yaml helm-values/values-v<old-version>.yaml

# Update new values file with any necessary changes
vim helm-values/values-v<new-version>.yaml
```

#### Step 3: Update Root Kustomization

```bash
# Edit kustomization.yaml
vim kustomization.yaml
```

Update the secretGenerator filename:

```yaml
# Before
secretGenerator:
  - name: <service>-values-base
    namespace: <namespace>
    type: Opaque
    files:
      - values.yaml=helm-values/values-v<old-version>.yaml  # Old version
    options:
      disableNameSuffixHash: true

# After
secretGenerator:
  - name: <service>-values-base
    namespace: <namespace>
    type: Opaque
    files:
      - values.yaml=helm-values/values-v<new-version>.yaml  # New version
    options:
      disableNameSuffixHash: true
```

#### Step 4: Update HelmRelease Version

```bash
# Edit helmrelease.yaml
vim helmrelease.yaml
```

Update the chart version:

```yaml
# Before
spec:
  chart:
    spec:
      chart: <chart-name>
      version: v<old-version>  # Old version

# After
spec:
  chart:
    spec:
      chart: <chart-name>
      version: v<new-version>  # New version
```

#### Step 5: Validate Changes

```bash
# Validate kustomization builds
kubectl kustomize .

# Check for syntax errors
kubectl apply --dry-run=client -f helmrelease.yaml
```

#### Step 6: Test in Non-Production

```bash
# Commit changes
git add .
git commit -m "Upgrade <service> from v<old> to v<new>"
git push

# Deploy to test cluster
flux reconcile source git opencenter-gitops-base
flux reconcile kustomization <service> --with-source

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
helm show values <repo-name>/<chart-name> --version v<new-version> > /tmp/<chart-name>-v<new-version>.yaml
```

### Step 2: Create New Base Values

```bash
cp helm-values/values-v<old-version>.yaml helm-values/values-v<new-version>.yaml
diff /tmp/<chart-name>-v<new-version>.yaml helm-values/values-v<old-version>.yaml
# Review differences and update values-v<new-version>.yaml as needed
```

### Step 3: Update Root Kustomization

```yaml
# kustomization.yaml
secretGenerator:
  - name: <service>-values-base
    namespace: <namespace>
    type: Opaque
    files:
      - values.yaml=helm-values/values-v<new-version>.yaml  # Updated
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
      version: v<new-version>  # Updated
```

### Step 5: Validate and Deploy

```bash
kubectl kustomize applications/base/services/<service>
git add applications/base/services/<service>
git commit -m "Upgrade <service> from v<old-version> to v<new-version>"
git push
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

### Handling CRD Changes

```bash
# If CRDs change, update them first
kubectl apply -f <new-crds.yaml>

# Then upgrade the service
flux reconcile kustomization <service> --with-source
```

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
# Revert to previous version
git revert <commit-hash>
git push

# Force reconciliation
flux reconcile source git opencenter-gitops-base
flux reconcile kustomization <service> --with-source

# Verify rollback
kubectl get helmrelease <service> -n <namespace>
helm list -n <namespace>
```

### Manual Rollback

```bash
# If git revert doesn't work, manually restore files
git checkout <previous-commit> -- applications/base/services/<service>/

# Commit and push
git add applications/base/services/<service>
git commit -m "Rollback <service> to v<old-version>"
git push
```

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

**Symptom:** Error: "file not found: helm-values/values-v<version>.yaml"

**Solution:**
```bash
# Verify file exists
ls -la helm-values/

# Check kustomization.yaml references correct filename
grep "values-v" kustomization.yaml
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
# Update CRDs first
kubectl apply -f <new-crds.yaml>

# Then upgrade service
flux reconcile kustomization <service> --with-source
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
- [Enterprise Components Pattern](../explanation/enterprise-components.md)
- [FluxCD HelmRelease Documentation](https://fluxcd.io/flux/components/helm/helmreleases/)
- [Helm Documentation](https://helm.sh/docs/)
