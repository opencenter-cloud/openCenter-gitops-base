---
id: values-layering
sidebar_label: Values Layering
description: Evidence-based description of base Helm values and consumer-provided overrides in openCenter-gitops-base.
doc_type: explanation
title: "Base, Override, and Enterprise Values"
audience: "platform engineers"
tags: [helm, values, overlays, enterprise]
---

# Base, Override, and Enterprise Values

**Purpose:** Explain which values are present in this repository and which values must be supplied by a consumer.

## Implemented base layer

Service values are stored beside the service, commonly under:

```text
applications/base/services/<service>/helm-values/
```

The catalog records the service version and packaging metadata; the Kustomization usually turns one or more of these files into a base Secret. For example, cert-manager generates `cert-manager-values-base` from `values-v1.21.2.yaml`. The observability Prometheus stack generates one base Secret from its chart values plus three override files for Alertmanager, Prometheus, and alerting rules.

Values filenames are repository data, not a universal naming contract: some services use `values-...`, while others use `hardened-values-...`.

## Consumer override layer

Many base HelmReleases declare an optional Secret with an `*-override` name after the base Secret. The base directory does not create that Secret. A consuming cluster repository is responsible for:

- creating the expected Secret and key;
- setting cluster-specific hosts, storage, endpoints, replicas, or other overrides;
- supplying credentials and custom resources that are not part of the base.

The checked-in dev-cluster example implements this pattern for MetalLB only, through its `metallb-values-override` Secret. Cert-manager's base `HelmRelease` has an optional override reference, but this checkout does not implement a cert-manager override Secret in the dev-cluster example.

## Private or enterprise layer

No private enterprise repository is present in this checkout. The catalog contains an `enterprise` blueprint, but that is inventory membership, not an implementation of a private values layer. If a consumer has a private repository, that repository is responsible for its own patches, private chart/image sources, authentication, and additional values. Exact merge behavior and names must be verified against that consumer's manifests.

## What is and is not guaranteed

**Implemented:** base values files, Kustomize generators, and optional override references where declared by each service.

**Consumer responsibility:** activation, override Secret creation, secrets, environment-specific values, and private-repository composition.

**Not established here:** a universal three-layer file layout, a universal override name, or the final values rendered in a live cluster.

## Related

- [Architecture Explanation](architecture.md)
- [GitOps Workflow](gitops-workflow.md)
- [Enterprise Components Pattern](enterprise-components.md)
- [Catalog Schema](../catalog/schema.md)
