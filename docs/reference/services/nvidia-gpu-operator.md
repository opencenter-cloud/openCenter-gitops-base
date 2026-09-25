---
id: service-nvidia-gpu-operator
title: "nvidia-gpu-operator"
sidebar_label: nvidia-gpu-operator
description: Reference for the NVIDIA GPU Operator service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, ML platform teams"
tags: [nvidia, gpu, mig, operator]
---

# NVIDIA GPU Operator

**Purpose:** For platform engineers, ML platform teams, documents the NVIDIA GPU Operator service in openCenter-gitops-base.

`nvidia-gpu-operator` deploys the NVIDIA GPU Operator to automate GPU driver, toolkit, device plugin, and telemetry management on Kubernetes nodes.

## What This Repo Deploys

- `Namespace/gpu-operator`
- `HelmRelease/gpu-operator`
- Base values Secret: `gpu-operator-values-base`
- Optional override Secret: `gpu-operator-values-override`

## When to Use It

- Nodes with NVIDIA GPUs need automated driver and toolkit management.

## GPU and MIG Configuration

The committed values file is `helm-values/values-v26.7.0.yaml`. It enables NFD, the GPU driver, toolkit, CDI, and DCGM exporter; `devicePlugin` is empty. The file contains commented MIG guidance, but no MIG-specific values variant is committed. MIG configuration is therefore **consumer-supplied/planned**, not a base-repository deployment feature.

If a consumer enables a supported MIG configuration, it must apply the matching node configuration after deployment, for example:

```bash
kubectl label nodes <node-name> nvidia.com/mig.config=all-1g.10gb --overwrite
```

## Configuration Surfaces

- Service path: `applications/base/services/nvidia-gpu-operator/`
- Namespace: `gpu-operator`
- Flux object: `HelmRelease/gpu-operator`
- Source: `https://helm.ngc.nvidia.com/nvidia`
- Chart version: `v26.7.0`

The catalog declares `node-feature-discovery` as a prerequisite, although the committed chart values also enable NFD as a subchart. GPU driver installation, node taints, MIG profiles, and workload scheduling remain hardware- and consumer-specific.

## Upstream References

- [NVIDIA GPU Operator docs](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html)
- [MIG with GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-mig.html)
- [MIG User Guide](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html)
