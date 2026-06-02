---
id: kyverno-config-guide
title: "Kyverno Configuration Guide"
sidebar_label: Kyverno
description: How to configure Kyverno policy-engine and ruleset layers in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [kyverno, policy, security, kubernetes]
---

# Kyverno Configuration Guide

Use this guide when a cluster repo needs to tune the Kyverno controller or layer additional policies on top of the base service.

## Service Layout in This Repo

The Kyverno service is split into:

- `policy-engine/` for the Helm-based controller installation
- `default-ruleset/` for the baseline policy bundle

Clusters normally customize:

- controller resources and replica count through `kyverno-values-override`
- additional cluster policies as separate manifests in the cluster repo
- whether the default ruleset is used as-is or selectively patched

## Override Values Pattern

The base `HelmRelease` reads:

- `Secret/kyverno-values-base` with key `values.yaml`
- optional `Secret/kyverno-values-override` with key `override.yaml`

Example:

```yaml
admissionController:
  replicas: 2
  container:
    resources:
      requests:
        cpu: 200m
        memory: 256Mi

backgroundController:
  enabled: true
```

## Policy Design Guidance

Good cluster layering patterns are:

- keep broadly reusable baseline controls in the base ruleset
- add environment-specific policies in the cluster repo
- start with `Audit` for new policies before switching to `Enforce`

Example cluster-local policy:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Audit
  rules:
    - name: check-team-label
      match:
        any:
          - resources:
              kinds:
                - Deployment
      validate:
        message: team label is required
        pattern:
          metadata:
            labels:
              team: "?*"
```

## Verification

```bash
kubectl get helmrelease -n kyverno kyverno
kubectl get pods -n kyverno
kubectl get cpol,pol -A
kubectl get policyreport,clusterpolicyreport -A
```

Healthy signs:

- Kyverno controller Pods are `Running`
- `HelmRelease/kyverno` is `Ready=True`
- policy reports are being generated

## Common Failure Modes

Admission requests time out:
- increase controller resources or reduce expensive policy patterns

Unexpected workload rejections:
- inspect matching policies and whether they are `Audit` or `Enforce`

Generate or mutate rules do not behave as expected:
- check match/exclude blocks and background mode behavior

## Related Docs

- [Kyverno Service Reference](../../reference/services/kyverno.md)
