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

## MIG Support

A MIG-enabled values variant (`values-v26.3.2-mig.yaml`) is included for clusters with MIG-capable GPUs (A100, A30, H100, H200). It enables:

- `mig.strategy: mixed` — allows both MIG and non-MIG GPUs on the same node
- `migManager.enabled: true` — deploys MIG Manager to handle MIG reconfiguration

After deployment, label nodes with the desired profile:

```bash
kubectl label nodes <node-name> nvidia.com/mig.config=all-1g.10gb --overwrite
```

## Configuration Surfaces

- Service path: `applications/base/services/nvidia-gpu-operator/`
- Namespace: `gpu-operator`
- Flux object: `HelmRelease/gpu-operator`
- Source: `https://helm.ngc.nvidia.com/nvidia`

## Upstream References

- [NVIDIA GPU Operator docs](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html)
- [MIG with GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-mig.html)
- [MIG User Guide](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html)
