# Node Feature Discovery – Base Configuration

This directory contains the **base manifests** for deploying [Node Feature Discovery (NFD)](https://github.com/kubernetes-sigs/node-feature-discovery). It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

## Public Repository Scope

- This public repository contains the **base** NFD deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Node Feature Discovery

- Detects hardware features and system configuration on Kubernetes nodes and advertises them as node labels.
- Labels nodes with CPU capabilities (SSE, AVX, etc.), PCI devices, USB devices, kernel features, and more.
- Enables GPU operators, storage drivers, and schedulers to select appropriate nodes via label selectors.
- Commonly deployed as a dependency for NVIDIA GPU Operator and AMD GPU Operator.
- Runs as a DaemonSet (nfd-worker) on all nodes with a controller (nfd-master) for label management.

## Prerequisites

- Kubernetes v1.24+.
- If deploying NFD standalone, disable the NFD sub-chart in GPU operators (`nfd.enabled: false` for NVIDIA, `node-feature-discovery.enabled: false` for AMD).

## Common Overrides

| Parameter | Description | Default |
|-----------|-------------|---------|
| `master.replicaCount` | NFD master replicas | `1` |
| `gc.enable` | Enable garbage collector | `true` |
| `worker.config` | Worker feature detection config | `{}` |

## Repository implementation

- Source path: `applications/base/services/node-feature-discovery/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `node-feature-discovery` and reads `nfd-values-base` plus the optional `nfd-values-override` Secret.
- Base values: `helm-values/values-0.19.0.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/node-feature-discovery/` to validate the local manifests. NFD reports detected features but does not install device drivers or schedule workloads. Avoid running the standalone deployment together with an enabled GPU-operator NFD sub-chart unless the cluster design explicitly accounts for both.
