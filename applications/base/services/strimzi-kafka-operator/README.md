# Strimzi Kafka Operator – Base Configuration

This directory contains the **base manifests** for deploying the
[Strimzi Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator)
to run Apache Kafka on Kubernetes using a Kubernetes-native, operator-driven workflow.

It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/strimzi-kafka-operator.md).

## About Strimzi Kafka Operator

- Provides a Kubernetes operator to deploy and manage **Apache Kafka** and its related components using Custom Resource Definitions (CRDs).
- Manages Kafka lifecycle operations including **scaling, rolling upgrades, configuration changes, and automated reconciliation**.
- Supports Kafka deployment using Kubernetes-native constructs such as **StatefulSets**, Services, and PodDisruptionBudgets.
- Enables secure Kafka clusters with built-in support for **TLS encryption**, authentication (TLS, SCRAM), and authorization patterns.
- Allows Kafka operational resources (topics, users, quotas) to be managed declaratively via **KafkaTopic** and **KafkaUser** CRDs.
- Commonly used to operate **production-grade Kafka on Kubernetes** with consistent configuration and standardized operational practices across environments.

## Repository implementation

- Source path: `applications/base/services/strimzi-kafka-operator/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `kafka-system` and reads `kafka-api-values-base` plus the optional `kafka-api-values-override` Secret.
- Base values: `helm-values/values-0.50.0.yaml`; the OCI chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/strimzi-kafka-operator/` to validate the local manifests. This installs the operator but does not create Kafka clusters, topics, users, storage, or broker credentials. Those resources and their security policy belong in a consuming overlay.
