# KubeRay Operator – Base Configuration

This directory contains the **base manifests** for deploying the [KubeRay Operator](https://github.com/ray-project/kuberay). It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

## Public Repository Scope

- This public repository contains the **base** KubeRay Operator deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## KubeRay Operator

- Kubernetes operator for deploying and managing Ray clusters, jobs, and services.
- Provides three CRDs: RayCluster, RayJob, and RayService.
- Manages Ray cluster lifecycle including creation, deletion, autoscaling, and fault tolerance.
- RayJob automatically creates clusters and submits jobs; RayService provides zero-downtime upgrades.
- Integrates with Kueue, Volcano, and Apache YuniKorn for job queuing.

## Prerequisites

- Kubernetes v1.26+.

## Common Overrides

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Operator image | `quay.io/kuberay/operator` |
| `image.tag` | Operator image tag | chart appVersion |
| `watchNamespace` | Restrict operator to a namespace | `""` (all) |
