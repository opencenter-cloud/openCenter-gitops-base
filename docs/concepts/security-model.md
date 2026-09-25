---
id: security-model
sidebar_label: Security Model
description: Security-related resources present in openCenter-gitops-base and boundaries that remain consumer or runtime responsibilities.
doc_type: explanation
title: "Security Model and Known Gaps"
audience: "security engineers, platform engineers, architects"
tags: [security, policy, architecture]
---

# Security Model and Known Gaps

**Purpose:** Record security resources that are implemented in this repository and avoid presenting optional chart values or plans as cluster-wide controls.

## Implemented resources

- `kyverno/policy-engine` contains a HelmRelease for Kyverno 3.9.1.
- `kyverno/default-ruleset` contains 17 `ClusterPolicy` resources, and its Kustomization includes them.
- `sealed-secrets` contains a HelmRelease for chart version 2.20.0 and its base values.
- Several service namespaces carry Pod Security Admission labels. The labels are not uniform: some namespaces explicitly use `privileged`, while others use privileged enforcement with baseline audit/warn settings.
- Keycloak includes OLM resources and RBAC manifests; `rbac-manager` is a separate catalogued service.

These resources are installable content. They do not prove that a cluster has selected the paths, that admission is healthy, or that all workloads comply.

## Controls not evidenced as base-owned policy

No `.sops.yaml`, SOPS-encrypted manifest, `NetworkPolicy` manifest, or Istio `PeerAuthentication` resource is present in this checkout. Helm values contain options/comments related to network policy and Pod Security, but those are not evidence of rendered resources in every cluster.

The repository does contain the Sealed Secrets chart. Sealed Secrets and SOPS are different mechanisms; this base repository does not establish a SOPS workflow. If a consumer uses SOPS, key storage, encryption rules, Flux integration, rotation, and recovery are consumer responsibilities and must be documented there.

Likewise, audit logging, image scanning/signature verification, network segmentation, mTLS, and cluster-wide RBAC policy are not established by the base manifests reviewed here. A consuming repository or cluster platform may add them, but that behavior is outside this repository's evidence.

## Security boundary

The base can provide policy-engine and secret-management building blocks. It does not define a complete production security posture, compliance mapping, threat model, or live-cluster assessment. No production-readiness rating or remediation schedule is derived here.

## Caveat for consumers

Before enabling a service, inspect its namespace labels, values, source credentials, required secrets, and any workload custom resources. Confirm the resulting resources with the consuming repository's validation and the cluster's admission/controller status.

## Related

- [GitOps Workflow](gitops-workflow.md)
- [Base, Override, and Enterprise Values](three-tier-values.md)
- [Enterprise Components Pattern](enterprise-components.md)
