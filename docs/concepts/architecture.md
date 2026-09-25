---
id: architecture-explanation
title: "Architecture Explanation"
sidebar_label: Architecture
description: Repository-backed architecture of openCenter-gitops-base, including IaC, service manifests, and consumer boundaries.
doc_type: explanation
audience: "architects, platform engineers"
tags: [architecture, gitops, fluxcd, kubespray, design]
---

# Architecture Explanation

**Purpose:** Describe what is implemented in this repository and what must be supplied by a consuming repository.

## Implemented in this repository

The repository contains two distinct implementation areas:

- `iac/` contains Terraform/OpenTofu inputs and templates for infrastructure and Kubernetes bootstrap. The tree includes Kubespray and OpenStack providers.
- `applications/` contains reusable Kubernetes service content. Most service directories use Kustomize to compose a namespace, source, `HelmRelease`, and values Secret; other directories use OLM resources, remote Kustomize resources, or staged custom resources.

The service inventory is also represented by catalog fragments under `applications/base/services/*/catalog.yaml`, the generated `applications/catalog.lock.yaml`, JSON Schema, and blueprint files. The committed lock currently contains 47 service entries and 11 blueprints, matching the repository's 47 service directories. KEDA is included, and the catalog coverage gate passes.

## Repository boundary

This repository provides reusable content. It does not, by itself, contain a cluster's Flux source and install intent. The checked-in example overlay demonstrates that separation: Flux `Kustomization` objects live under `examples/`, reference `GitRepository` objects, and select paths such as `applications/base/services/cert-manager`.

The following are consumer responsibilities, not implemented here:

- selecting services for a particular cluster;
- supplying cluster-specific Flux objects, override values, custom resources, and secrets;
- choosing a repository ref and maintaining any environment-specific overlay;
- any private-repository composition or private artifact configuration.

The checkout contains no private enterprise repository. The catalog's `enterprise` blueprint is inventory metadata; it is not evidence that a private enterprise overlay is present or automatically consumed.

## Implemented service shapes

The catalog records these packaging types:

| Shape | Repository evidence |
| --- | --- |
| `helmRepository` | `HelmRelease` with an HTTPS Helm source |
| `ociHelm` | `HelmRelease` with an OCI source |
| `gitRepository` | `HelmRelease` using a Git source/ref, used by three catalog entries |
| `olmSubscription` | `Subscription` and `OperatorGroup` resources |
| `remoteKustomize` | Kustomize content pinned to remote manifests |
| `composite` | A parent with separately deployable subpaths and no single root install |

Composite entries include `ceph-csi`, `observability`, `kyverno`, `istio`, and `keycloak`. Their child paths must be selected by the consumer in the required order where the manifests express dependencies.

## Flux flow shown by the examples

The example resources implement this pattern:

```text
GitRepository -> Flux Kustomization -> base service path
                                      -> HelmRelease -> Helm chart
                                      -> or plain/OLM/custom resources
```

For example, the cert-manager Kustomization depends on `sources`, references `opencenter-cert-manager`, applies `applications/base/services/cert-manager`, and health-checks the resulting `HelmRelease`. The base service itself defines the namespace, public chart source, release, base values Secret, and optional override Secret.

The example source manifests currently use `https://github.com/rackerlabs/openCenter-gitops-base.git` on the `main` branch. This is example configuration, not a repository-wide claim about the canonical consumer URL or ref.

## Configuration ownership

Implemented base ownership is visible in service `helm-values/` files and Kustomize `secretGenerator` entries. A representative HelmRelease declares the base Secret first and an optional `*-override` Secret second. The override Secret is not created by the base service directory.

Cluster-specific values, secrets, and custom resources are therefore consumer responsibilities. Private chart sources, private images, and enterprise-only patches are also outside this checkout; their implementation and behavior cannot be verified from this repository.

## IaC and GitOps are separate stages

The repository contains both infrastructure provisioning inputs and post-bootstrap application content, but no evidence that one automatically invokes the other. IaC establishes infrastructure and cluster inputs; a consumer's Flux configuration applies selected application paths after the cluster is available.

## Limitations

This page documents repository structure and checked-in examples. It does not assert live-cluster state, successful reconciliation, private overlay behavior, or a particular production topology. Those require the consuming repository and cluster status.

## Related

- [GitOps Workflow](gitops-workflow.md)
- [Base, Override, and Enterprise Values](three-tier-values.md)
- [Enterprise Components Pattern](enterprise-components.md)
- [Service Catalog](../catalog/index.md)
