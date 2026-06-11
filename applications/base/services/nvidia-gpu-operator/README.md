# NVIDIA GPU Operator – Base Configuration

This directory contains the **base manifests** for deploying the [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html). It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

## Public Repository Scope

- This public repository contains the **base** NVIDIA GPU Operator deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## NVIDIA GPU Operator

- Automates the provisioning and lifecycle management of all NVIDIA software components needed to run GPU workloads on Kubernetes.
- Deploys the NVIDIA GPU driver, Container Toolkit, Device Plugin, DCGM Exporter, and Node Feature Discovery as operands.
- Uses Container Device Interface (CDI) for GPU injection into workload containers (default since v25.10).
- Supports Multi-Instance GPU (MIG), time-slicing, GPUDirect RDMA/Storage, and vGPU configurations.
- Requires the `gpu-operator` namespace to have the `pod-security.kubernetes.io/enforce: privileged` label.
- Provides GPU telemetry via DCGM Exporter for Prometheus-based observability stacks.

## Prerequisites

- Worker nodes with NVIDIA GPUs (PCI vendor ID `0x10de`).
- Container runtime (containerd or CRI-O) configured on GPU nodes.
- If Node Feature Discovery is already deployed, set `nfd.enabled: false` in the override values.

## Common Overrides

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nfd.enabled` | Deploy NFD sub-chart | `true` |
| `driver.enabled` | Deploy GPU driver containers | `true` |
| `driver.version` | Override driver version | chart default |
| `toolkit.enabled` | Deploy NVIDIA Container Toolkit | `true` |
| `dcgmExporter.enabled` | Deploy DCGM Exporter | `true` |
| `cdi.enabled` | Enable CDI-based device injection | `true` |
| `mig.strategy` | MIG strategy (`single` or `mixed`) | unset (MIG disabled) |
| `migManager.enabled` | Deploy MIG Manager daemonset | `false` |

## MIG Support

A MIG-enabled values variant is provided at `helm-values/values-v26.3.2-mig.yaml`. To use it, reference this file in your cluster kustomization:

```yaml
secretGenerator:
    - name: gpu-operator-values-base
      namespace: gpu-operator
      type: Opaque
      files:
        - values.yaml=helm-values/values-v26.3.2-mig.yaml
      options:
        disableNameSuffixHash: true
```

After deployment, label nodes with the desired MIG profile:

```bash
kubectl label nodes <node-name> nvidia.com/mig.config=all-1g.10gb --overwrite
```

MIG Manager auto-generates profiles per node. For custom profiles, provide a ConfigMap via `migManager.config` in the override values. See the [NVIDIA MIG documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-mig.html) for details.
