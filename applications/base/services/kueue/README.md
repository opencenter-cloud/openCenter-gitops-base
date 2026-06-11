# Kueue – Base Configuration

This directory contains the **base manifests** for deploying [Kueue](https://kueue.sigs.k8s.io/). It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

## Public Repository Scope

- This public repository contains the **base** Kueue deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Kueue

- Kubernetes-native job queueing system for managing batch workloads, ML training jobs, and GPU-intensive applications.
- Implements fair sharing, resource quotas, preemption, and priority-based scheduling across namespaces.
- Supports batch/job, JobSets, Kubeflow training jobs, RayJobs, Argo Workflows, and more.
- Provides topology-aware scheduling for GPU/accelerator locality.
- Uses internal cert management by default; can integrate with external cert-manager.

## Prerequisites

- Kubernetes v1.29+.
- Optional: cert-manager if disabling internal cert management.
- Optional: prometheus-operator for metrics scraping.

## Common Overrides

| Parameter | Description | Default |
|-----------|-------------|---------|
| `manageJobsWithoutQueueName` | Auto-manage jobs without queue annotation | `true` |
| `internalCertManagement.enable` | Use built-in cert management | `true` |
| `integrations.frameworks` | Enabled job framework integrations | `["batch/job"]` |
