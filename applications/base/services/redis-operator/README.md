# Redis Operator

| Field | Value |
|-------|-------|
| **Source** | [OT-CONTAINER-KIT/redis-operator](https://github.com/OT-CONTAINER-KIT/redis-operator) |
| **Namespace** | `redis-operator` |
| **Chart** | `redis-operator` |
| **Version** | `0.26.1` |
| **AppVersion** | `0.26.1` |

## Overview

The OT Container Kit Redis Operator manages Redis deployments on Kubernetes across multiple topologies:

- **Redis** — standalone single-node instances
- **RedisCluster** — sharded Redis cluster with automatic failover
- **RedisReplication** — master-replica replication setups
- **RedisSentinel** — high-availability with Sentinel monitoring

## Custom Resource Definitions

| CRD | Purpose |
|-----|---------|
| `Redis` | Standalone Redis instance |
| `RedisCluster` | Sharded cluster with hash-slot distribution |
| `RedisReplication` | Master-replica replication |
| `RedisSentinel` | Sentinel-based HA monitoring |

## Features

- Built-in monitoring via redis-exporter (Prometheus-compatible metrics)
- TLS encryption support
- Password authentication
- IPv4 and IPv6 dual-stack support
- Redis >= 6.x compatibility

## Prerequisites

- **cert-manager** — required for webhook certificate management (enabled via `certManager.enabled: true` in values)

## Values Layering

| Secret | Purpose |
|--------|---------|
| `redis-operator-values-base` | Base values from `helm-values/values-0.26.1.yaml` |
| `redis-operator-values-override` | Cluster-specific overrides (optional) |

## Repository implementation

- Source path: `applications/base/services/redis-operator/`.
- Flux entrypoint: `kustomization.yaml`; it renders the namespace, HelmRepository, HelmRelease, and `redis-operator-values-base` Secret.
- Base values: `helm-values/values-0.26.1.yaml`.
- The optional `redis-operator-values-override` Secret is merged after the base values.

## Validation and limitations

Run `kustomize build applications/base/services/redis-operator/` to validate the local manifests. This deploys the operator and CRDs but does not create Redis resources, storage, credentials, or backup targets. The chart values file retains the upstream chart-version comment; the reconciled Helm chart version is the `0.26.1` version in `helmrelease.yaml`.
