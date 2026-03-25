---
id: service-strimzi-kafka-operator
title: "strimzi-kafka-operator"
sidebar_label: strimzi-kafka-operator
description: Reference for the Strimzi Kafka Operator service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, data platform teams"
tags: [kafka, strimzi, operator]
---

# Strimzi Kafka Operator

`strimzi-kafka-operator` deploys the Strimzi operator so Kafka clusters, topics, and users can be managed declaratively in Kubernetes.

## What This Repo Deploys

- `Namespace/kafka-system`
- `HelmRelease/strimzi-kafka-operator`
- Base values Secret: `kafka-api-values-base`
- Optional override Secret: `kafka-api-values-override`

## When to Use It

- Kafka should be operated as a platform service inside the cluster.

## Example

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: platform-kafka
spec:
  kafka:
    replicas: 3
```

## Configuration Surfaces

- Service path: `applications/base/services/strimzi-kafka-operator/`
- Namespace: `kafka-system`
- Flux object: `HelmRelease/strimzi-kafka-operator`
- Source: `oci://quay.io/strimzi-helm`

## Upstream References

- [Strimzi docs](https://strimzi.io/documentation/)
- [Strimzi operator overview](https://strimzi.io/docs/operators/latest/overview)
