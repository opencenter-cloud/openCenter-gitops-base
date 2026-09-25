---
id: gitops-workflow
sidebar_label: GitOps Workflow
description: Repository-backed Flux and Kustomize workflow for consuming openCenter-gitops-base service paths.
doc_type: explanation
title: "GitOps Workflow in openCenter"
audience: "platform engineers, architects"
tags: [gitops, fluxcd, reconciliation, workflow]
---

# GitOps Workflow in openCenter

**Purpose:** Explain the workflow implemented by the checked-in Flux examples and base manifests without treating the examples as a complete cluster configuration.

## Implemented boundary

`openCenter-gitops-base` supplies service paths. A consuming repository supplies Flux source and install intent. The example overlay contains both kinds of Flux resources outside `applications/base/services/`:

- `GitRepository` objects under `examples/applications/overlays/dev-cluster/services/sources/`;
- Flux `Kustomization` objects under `.../services/fluxcd/`.

The base repository has no single root Flux object that activates every service.

## Flow evidenced by the examples

```text
GitRepository -> Flux Kustomization -> selected base path
                                      -> HelmRelease -> chart source
                                      -> or manifests / OLM resources
```

The example cert-manager, Headlamp, MetalLB, and Gateway API Kustomizations each select a base service path and depend on the `sources` Kustomization. Their intervals, target namespaces, pruning, waits, and health checks are properties of those examples, not defaults that every consumer must use.

The example GitRepository objects currently point to the `rackerlabs/openCenter-gitops-base.git` repository and `main`. Consumers must own and verify their repository URL, ref, path, and credentials.

## Base service reconciliation content

For a Helm service, the base commonly contains:

1. a namespace (flat or nested);
2. a `HelmRepository` or other chart source;
3. a `HelmRelease`;
4. a Kustomize-generated base values Secret;
5. an optional override Secret reference.

The cert-manager manifests are a concrete example. Its release is interval `5m`, enables Helm drift detection, retries installation three times, does not retry upgrades, and reads `cert-manager-values-base` followed by an optional `cert-manager-values-override`. These settings are manifest facts for that release, not a universal policy; the checked-in dev-cluster example does not create that cert-manager override Secret.

Not every service is Helm-based. The catalog and manifests also contain:

- OLM `Subscription`/`OperatorGroup` services;
- remote Kustomize services such as `external-snapshotter` and `olm`;
- composite services such as `observability`, `ceph-csi`, `istio`, `kyverno`, and `keycloak`.

## Ordering and overrides

Where the example needs a prerequisite, it declares `dependsOn`; where a service is composite, child paths and their `requires` metadata describe the intended relationship. Flux dependency objects for a real cluster remain consumer-owned.

The base manifests declare base values and, for many Helm releases, an optional override Secret. The consuming repository is responsible for creating a correctly named override, supplying secrets, and selecting any additional custom resources. A private enterprise repository, if used by a consumer, is responsible for private sources, images, and patches; that repository is not present here.

## What this page does not establish

Repository manifests do not prove that a live cluster has reconciled successfully, that every catalog entry is deployable by an external CLI, or that private overlays behave in a particular way. Those are consumer or runtime checks.

## Related

- [Architecture Explanation](architecture.md)
- [Base, Override, and Enterprise Values](three-tier-values.md)
- [Service Catalog](../catalog/index.md)
