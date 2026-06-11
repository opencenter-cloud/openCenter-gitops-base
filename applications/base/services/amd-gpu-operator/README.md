# AMD GPU Operator – Base Configuration

This directory contains the **base manifests** for deploying the [AMD GPU Operator](https://github.com/ROCm/gpu-operator). It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

## Public Repository Scope

- This public repository contains the **base** AMD GPU Operator deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## AMD GPU Operator

- Simplifies deployment and management of AMD Instinct GPU accelerators within Kubernetes clusters.
- Deploys K8s Device Plugin, Node Labeller, Device Config Manager, Device Metrics Exporter, and KMM Operator.
- Supports Dynamic Resource Allocation (DRA) as an alternative to the traditional device plugin.
- Provides GPU partitioning configuration via DeviceConfig custom resources.
- Requires cert-manager to be installed in the cluster prior to deployment.

## Prerequisites

- Kubernetes v1.29.0+
- Worker nodes with AMD Instinct GPUs.
- [cert-manager](../cert-manager/) installed in the cluster.
- If Node Feature Discovery is already deployed, set `node-feature-discovery.enabled: false` in override values.

## Common Overrides

| Parameter | Description | Default |
|-----------|-------------|---------|
| `node-feature-discovery.enabled` | Deploy NFD sub-chart | `true` |
| `kmm.enabled` | Deploy KMM sub-chart | `true` |
| `kmm.watch` | Enable KMM driver watching | `true` |
| `remediation.enabled` | Auto node remediation | `true` |
| `deviceConfig.spec.draDriver.enable` | Use DRA instead of device plugin | `false` |
