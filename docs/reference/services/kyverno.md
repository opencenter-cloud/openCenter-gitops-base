---
id: service-kyverno
title: "kyverno"
sidebar_label: kyverno
description: Reference for the Kyverno policy engine service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, security teams"
tags: [kyverno, policy, security]
---

# Kyverno

`kyverno` is the Kubernetes-native policy engine used in this repository for validation, mutation, generation, and policy reporting. The service is split into a controller deployment and a default ruleset bundle.

## What This Repo Deploys

- `policy-engine/` with `HelmRelease/kyverno`
- `default-ruleset/` with baseline policy resources
- Base values Secret: `kyverno-values-base`
- Optional override values Secret: `kyverno-values-override`

## When to Use It

- You need admission-time guardrails for workloads and namespaces.
- You want platform defaults enforced through Kubernetes-native policy resources.
- You want compliance visibility through policy reports.

## Key Integration Points

- Pod Security standards and namespace controls often complement Kyverno policies.
- Policies may affect Helm releases and application workloads across the cluster.
- Observability stacks usually scrape Kyverno metrics and policy reports.

## Example

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-run-as-nonroot
spec:
  validationFailureAction: Enforce
```

## Configuration Surfaces

- Service path: `applications/base/services/kyverno/`
- Namespace: `kyverno`
- Flux object: `HelmRelease/kyverno` under `policy-engine/`
- Policy bundle: `default-ruleset/`

## Related Docs

- [Kyverno Configuration Guide](../../how-to/services/kyverno.md)

## Upstream References

- [Kyverno docs](https://kyverno.io/docs/)
- [Kyverno policy library](https://kyverno.io/policies/)
- [Kyverno Helm chart](https://artifacthub.io/packages/helm/kyverno/kyverno)
