# Redis Operator

| Field | Value |
|-------|-------|
| **Source** | [OT-CONTAINER-KIT/redis-operator](https://github.com/OT-CONTAINER-KIT/redis-operator) |
| **Namespace** | `redis-operator` |
| **Chart** | `redis-operator` |
| **Version** | `0.25.0` |
| **AppVersion** | `0.25.0` |

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
| `redis-operator-values-base` | Base values from `helm-values/values-0.25.0.yaml` |
| `redis-operator-values-override` | Cluster-specific overrides (optional) |
