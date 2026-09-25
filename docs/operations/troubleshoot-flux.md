---
id: troubleshoot-flux
sidebar_label: Troubleshoot Flux
description: Troubleshooting guide for FluxCD reconciliation issues in openCenter clusters.
doc_type: how-to
title: "Troubleshoot FluxCD Reconciliation"
audience: "platform engineers"
tags: [fluxcd, troubleshooting, gitops, reconciliation]
---

# Troubleshoot FluxCD Reconciliation

**Purpose:** For platform engineers, shows how to debug FluxCD reconciliation issues, covering status checks, log analysis, common errors, and remediation steps. The checked-in example uses GitRepository `opencenter-cert-manager` and install Kustomization `cert-manager-base`, both in `flux-system`; substitute names only after checking the full consumer overlay.

## Prerequisites

- FluxCD installed in cluster
- flux CLI installed (`flux version`)
- kubectl access to cluster
- Basic understanding of FluxCD resources

## Quick Diagnostics

### Check overall Flux health

```bash
# Check all Flux components
flux check

# Check Flux controllers
kubectl get pods -n flux-system

# Check Flux version
flux version
```

Expected output:
```
✔ All checks passed
```

### Check resource status

```bash
# Check all Flux resources in every namespace
flux get all --all-namespaces

# Check specific resource types in every namespace
flux get sources git --all-namespaces
flux get sources helm --all-namespaces
flux get helmreleases --all-namespaces
flux get kustomizations --all-namespaces
```

## Common Issues and Solutions

### Issue 1: GitRepository Authentication Failure

**Symptom:**

```bash
flux get sources git --all-namespaces
NAME                    READY   MESSAGE
opencenter-cert-manager         False   fetch failed
```

**Diagnosis:**

```bash
kubectl describe gitrepository opencenter-cert-manager -n flux-system
```

Look for:
```
Message: failed to checkout and determine revision
```

**Solution:**

Check the URL, ref, and credentials against the consumer repository's source definition. Public sources may use HTTPS without a `secretRef`; private Git sources require the consumer's configured authentication Secret. Do not replace a working private source with an invented URL.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: opencenter-cert-manager
  namespace: flux-system
spec:
  interval: 15m
  url: https://github.com/rackerlabs/openCenter-gitops-base.git
  ref:
    branch: main
```

Force reconciliation:

```bash
flux reconcile source git opencenter-cert-manager -n flux-system
```

### Issue 2: HelmRelease Stuck in "Installing"

**Symptom:**

```bash
flux get helmreleases --all-namespaces
NAME            READY   MESSAGE
cert-manager    False   install retries exhausted
```

**Diagnosis:**

```bash
kubectl describe helmrelease cert-manager -n cert-manager
```

Check events:

```bash
kubectl get events -n cert-manager --sort-by='.lastTimestamp'
```

View Helm controller logs:

```bash
flux logs --kind=HelmRelease --name=cert-manager --namespace=cert-manager
```

**Common Causes:**

1. **Helm repository not accessible**

```bash
flux get sources helm --all-namespaces
kubectl describe helmrepository jetstack -n cert-manager
```

2. **Chart version not found**

Check HelmRelease chart version:

```bash
kubectl get helmrelease cert-manager -n cert-manager -o jsonpath='{.spec.chart.spec.version}'
```

Check available versions:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm search repo jetstack/cert-manager --versions
```

3. **Values validation failed**

Check values secrets:

```bash
kubectl get secret cert-manager-values-base -n cert-manager
```

Decode and validate:

```bash
kubectl get secret cert-manager-values-base -n cert-manager -o jsonpath='{.data.values\.yaml}' | base64 -d | yq eval '.' -
```

**Solution:**

Suspend and resume HelmRelease:

```bash
flux suspend helmrelease cert-manager -n cert-manager
flux resume helmrelease cert-manager -n cert-manager
```

Use suspend/resume or fix the declared source and values first. Deleting a HelmRelease is a destructive break-glass action and is not required for normal reconciliation.

### Issue 3: Resources differ from the declared state

**Symptom:**

```bash
flux get kustomizations --all-namespaces
NAME            READY   MESSAGE
cert-manager-base    True    Applied revision: main@sha1:abc123, drift detected
```

**Diagnosis:**

```bash
kubectl describe kustomization cert-manager-base -n flux-system
```

**Cause:**

Resources were modified outside of Git (manual kubectl apply or Helm upgrade).

**Solution:**

View drifted resources:

```bash
flux diff kustomization cert-manager-base
```

Force reconciliation to restore Git state:

```bash
flux reconcile kustomization cert-manager-base -n flux-system --with-source
```

For Helm-managed resources, inspect drift detection on the `HelmRelease`, not the Flux `Kustomization`:

```bash
kubectl get helmrelease cert-manager -n cert-manager -o jsonpath='{.spec.driftDetection.mode}'
```

The base HelmRelease manifests set `driftDetection.mode: enabled`; the consumer overlay must still reconcile the correct source and install Kustomization.

### Issue 4: SOPS Decryption Failed

**Symptom:**

```bash
flux get kustomizations --all-namespaces
NAME            READY   MESSAGE
cert-manager-base      False   decryption failed
```

**Diagnosis:**

```bash
kubectl describe kustomization cert-manager-base -n flux-system
```

Look for:
```
Message: failed to decrypt secret: no age key found
```

**Solution:**

Check age key secret exists:

```bash
kubectl get secret sops-age -n flux-system
```

If missing, create:

```bash
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/<cluster>_keys.txt \
  -n flux-system
```

Verify Kustomization references secret:

```bash
kubectl get kustomization cert-manager-base -n flux-system -o jsonpath='{.spec.decryption}'
```

Should show:
```json
{"provider":"sops","secretRef":{"name":"sops-age"}}
```

Force reconciliation:

```bash
flux reconcile kustomization cert-manager-base -n flux-system
```

### Issue 5: Dependency Wait Timeout

**Symptom:**

```bash
flux get kustomizations --all-namespaces
NAME                READY   MESSAGE
cert-manager-base  False   dependency 'sources' is not ready
```

**Diagnosis:**

```bash
kubectl describe kustomization cert-manager-base -n flux-system
```

Check dependency status:

```bash
flux get kustomizations -n flux-system
```

**Solution:**

Check dependency is healthy:

```bash
kubectl get kustomization sources -n flux-system
```

If dependency is stuck, troubleshoot it first.

If dependency is ready but not detected, force reconciliation:

```bash
flux reconcile kustomization sources -n flux-system
flux reconcile kustomization cert-manager-base -n flux-system
```

Increase timeout if needed:

```yaml
spec:
  dependsOn:
    - name: sources
  timeout: 10m  # Increase from default 5m
```

### Issue 6: Image Pull Errors

**Symptom:**

HelmRelease shows ready, but pods fail to start:

```bash
kubectl get pods -n cert-manager
NAME                           READY   STATUS             RESTARTS   AGE
cert-manager-5d7f9c8b6-abc12   0/1     ImagePullBackOff   0          2m
```

**Diagnosis:**

```bash
kubectl describe pod cert-manager-5d7f9c8b6-abc12 -n cert-manager
```

Look for:
```
Failed to pull image "registry.example.com/cert-manager:v1.18.2": rpc error: code = Unknown desc = failed to pull and unpack image
```

**Solution:**

Check image exists:

```bash
# For public images
docker pull registry.example.com/cert-manager:v1.18.2

# For private registries
kubectl get secret -n cert-manager | grep regcred
```

Create image pull secret if needed:

```bash
kubectl create secret docker-registry regcred \
  --docker-server=<registry-host> \
  --docker-username=<registry-user> \
  --docker-password=<registry-password> \
  -n cert-manager
```

Update HelmRelease values:

```yaml
imagePullSecrets:
  - name: regcred
```

### Issue 7: Resource Quota Exceeded

**Symptom:**

```bash
flux logs --kind=HelmRelease --name=my-service
Error: admission webhook denied the request: exceeded quota
```

**Diagnosis:**

```bash
kubectl describe resourcequota -n my-service
```

**Solution:**

Increase quota:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: my-service-quota
  namespace: my-service
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
```

Or reduce resource requests in Helm values.

### Issue 8: Webhook Timeout

**Symptom:**

```bash
flux logs --kind=Kustomization --name=my-service
Error: context deadline exceeded
```

**Diagnosis:**

Check admission webhooks:

```bash
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations
```

**Solution:**

Check webhook service is running:

```bash
kubectl get pods -n kyverno
kubectl get pods -n cert-manager
```

If webhook is down, suspend Kustomization temporarily:

```bash
flux suspend kustomization my-service
# Fix webhook
flux resume kustomization my-service
```

Increase timeout:

```yaml
spec:
  timeout: 10m
```

## Debugging Commands

### View Flux controller logs

```bash
# All controllers
flux logs

# Specific controller
flux logs --kind=Kustomization --name=cert-manager-base --namespace=flux-system

# Follow logs
flux logs --follow

# Last 100 lines
flux logs --tail=100
```

### Force reconciliation

```bash
# Reconcile source
flux reconcile source git opencenter-cert-manager -n flux-system

# Reconcile Kustomization
flux reconcile kustomization cert-manager-base -n flux-system

# Reconcile with source update
flux reconcile kustomization cert-manager-base -n flux-system --with-source

# Reconcile HelmRelease
flux reconcile helmrelease my-service -n my-service
```

### Suspend and resume

```bash
# Suspend (stop reconciliation)
flux suspend kustomization cert-manager-base -n flux-system

# Resume
flux resume kustomization cert-manager-base -n flux-system
```

### Export and inspect resources

```bash
# Export GitRepository
flux export source git opencenter-cert-manager -n flux-system

# Export HelmRelease
flux export helmrelease cert-manager -n cert-manager

# Export Kustomization
flux export kustomization cert-manager-base -n flux-system
```

### Trace reconciliation

```bash
# Trace Kustomization
flux trace kustomization cert-manager-base -n flux-system

# Shows:
# - Source
# - Dependencies
# - Applied resources
# - Health checks
```

## Verification Checklist

After resolving issues:

```bash
# 1. All sources are ready
flux get sources git --all-namespaces
flux get sources helm --all-namespaces

# 2. All Kustomizations are ready
flux get kustomizations --all-namespaces

# 3. All HelmReleases are ready
flux get helmreleases --all-namespaces

# 4. Inspect for suspended resources
flux get all --all-namespaces

# 5. Check recent events
kubectl get events -n flux-system --sort-by='.lastTimestamp' | tail -20
```

## Prevention Best Practices

1. **Pin versions** - Use specific tags/versions, not `latest`
2. **Test in non-production** - Validate changes before production
3. **Use health checks** - Configure readiness/liveness probes
4. **Set resource limits** - Prevent resource exhaustion
5. **Monitor Flux** - Set up alerts for reconciliation failures
6. **Backup age keys** - Store SOPS keys securely
7. **Document dependencies** - Clear dependency chains
8. **Use drift detection** - Catch manual changes
9. **Implement retries** - Configure remediation policies
10. **Regular upgrades** - Keep Flux up to date

## Emergency Procedures

### Complete Flux failure

If all Flux controllers are down:

```bash
# Check controller pods
kubectl get pods -n flux-system

# Reapply the committed Flux installation manifests from the cluster repo.
# Run from the cluster-repo root; do not uninstall Flux to recover it.
FLUX_MANIFEST_PATH="clusters/<cluster>/flux-system"
kubectl apply -k "$FLUX_MANIFEST_PATH"

# If the installation manifests are unavailable, bootstrap the approved
# cluster repository and path instead of deleting the existing installation.
flux bootstrap git \
  --url="<approved-git-url>" \
  --branch="<approved-branch>" \
  --path="<cluster-repo-bootstrap-path>"
```

After controllers recover, verify `flux check`, the `GitRepository`, and the `sources` and `cert-manager-base` Kustomizations before reconciling workloads.

### Rollback to previous version

```bash
# Find previous commit
git log --oneline

# Revert to previous commit
git revert HEAD
git push origin main

# Force reconciliation
flux reconcile source git opencenter-cert-manager -n flux-system
flux reconcile kustomization cert-manager-base -n flux-system --with-source
```

### Manual intervention required

If Flux cannot recover:

```bash
# Reapply the reviewed, declarative service overlay from the cluster-repo root.
# This is a break-glass action; commit the same correction to Git immediately.
SERVICE_OVERLAY_PATH="applications/overlays/<cluster>/services/<service>"
kubectl apply -k "$SERVICE_OVERLAY_PATH"

# Reconcile the declared install object after the repository is corrected.
flux reconcile kustomization cert-manager-base -n flux-system --with-source
```

## Next Steps

- Set up Flux monitoring (see [setup-observability.md](setup-observability.md))
- Configure Flux notifications (Slack, PagerDuty)
- Implement automated testing for Flux resources
- Create runbooks for common Flux issues
