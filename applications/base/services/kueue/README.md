# Kueue – Base Configuration

This directory contains the **base manifests** for deploying [Kueue](https://kueue.sigs.k8s.io/), the Kubernetes-native job queueing system.

## Public Repository Scope

- This public repository contains the **base** Kueue deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Kueue

- Manages job queueing with quotas and priorities on Kubernetes.
- Determines when jobs should be admitted (pods created) or preempted (pods deleted) based on resource availability.
- Integrates with Ray, Kubeflow Training Operator, Spark, and plain batch Jobs.
- Part of the Open Data Hub AI/ML training and compute stack.

## Prerequisites

- Kubernetes v1.29+.
- cert-manager (optional, for webhook TLS — Kueue has internal cert management by default).

## Common Overrides

| Parameter | Description | Default |
|-----------|-------------|---------|
| `controller.manager.resources.limits.memory` | Memory limit | `512Mi` |
| `enablePlainPod` | Enable plain Pod integration | `false` |
| `integrations.frameworks` | Enabled job frameworks | batch/job |
