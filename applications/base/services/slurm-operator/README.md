# Slinky Slurm Operator – Base Configuration

This directory contains the **base manifests** for deploying the [Slinky Slurm Operator](https://github.com/SlinkyProject/slurm-operator). It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

## Public Repository Scope

- This public repository contains the **base** Slurm Operator deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Slinky Slurm Operator

- Kubernetes operator to deploy and manage Slurm HPC clusters on Kubernetes (by SchedMD).
- Manages Slurm controller, NodeSets (compute nodes), and LoginSets lifecycle.
- Supports graceful node drain, scale-in, upgrades, and hybrid Slurm/Kubernetes environments.
- Automatically detects Slurm configuration changes and reconfigures with zero control-plane downtime.
- Requires cert-manager for webhook certificate management.

## Prerequisites

- Kubernetes v1.29+.
- [cert-manager](../cert-manager/) installed in the cluster.

## Deployment Notes

- The operator is split into two Helm charts: `slurm-operator-crds` (CRDs) and `slurm-operator` (controller).
- The operator HelmRelease depends on the CRDs HelmRelease via `dependsOn`.
- To deploy actual Slurm clusters, install the separate `slurm` Helm chart with appropriate NodeSet and partition configuration.
