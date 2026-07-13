# Milvus Operator

## Overview

Milvus is a cloud-native vector database designed for GenAI and RAG (Retrieval-Augmented Generation) applications. The Milvus Operator manages the full lifecycle of Milvus deployments on Kubernetes, supporting both standalone and cluster modes.

## Capabilities

- Declarative management of Milvus instances via custom resources
- Standalone and distributed cluster deployment modes
- Rolling upgrades with configurable strategies
- Health checks and automatic recovery
- Scaling of individual Milvus components (proxy, data node, index node, query node)

## Dependencies

| Dependency | Purpose | Provided by |
|------------|---------|-------------|
| cert-manager | Webhook TLS certificates | `applications/base/services/cert-manager/` |

The bundled cert-manager subchart is disabled in the base values. The platform-level cert-manager instance handles certificate issuance.

## Milvus Instance Dependencies

Milvus instances created by the operator require backing services:

| Component | Purpose | Options |
|-----------|---------|---------|
| etcd | Metadata storage | Bundled or external |
| Object storage | Segment/index persistence | MinIO (bundled) or S3-compatible |
| Message queue | Log streaming | Pulsar, Kafka, or NATs |

These are configured per-instance via the `Milvus` or `MilvusCluster` custom resource, not at the operator level.

## Version

| Field | Value |
|-------|-------|
| Chart version | 1.3.7 |
| App version | 1.3.7 |
| Namespace | `milvus-operator` |

## Customization

Place cluster-specific overrides in a sealed secret named `milvus-operator-values-override` in the `milvus-operator` namespace. The override secret is optional and merged on top of the base values.
