# Longhorn – Base Configuration

This directory contains the **base manifests** for deploying [Longhorn](https://longhorn.io/), a distributed block storage platform for Kubernetes clusters. It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/longhorn.md).

## Public Repository Scope

- This public repository contains the **base** Longhorn deployment backed by upstream public artifacts.
- If private image rewrites, private chart sources, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## What This Base Includes

- `Namespace/longhorn-system`
- `HelmRelease/longhorn`
- base chart values from the service `helm-values/` directory
- optional cluster override support through `longhorn-values-override`
- additional storage classes:
  - `longhorn-general`
  - `longhorn-general-multi-attach`

## Longhorn

- Provides replicated block storage for Kubernetes workloads without requiring a cloud storage provider.
- Supports snapshots, backups, restores, and volume expansion for stateful applications.
- Exposes CSI-based storage classes that application workloads can consume through standard PVCs.
- Works best when node disks, replica placement, and backup targets are planned explicitly per cluster.
