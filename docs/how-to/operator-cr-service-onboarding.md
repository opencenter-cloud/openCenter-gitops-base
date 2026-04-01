---
id: operator-cr-service-onboarding
sidebar_label: Operator CR Service Onboarding
description: Step-by-step guide for onboarding services where the operator is installed with Helm and the workload is created by custom resources from the cluster overlay repo.
doc_type: how-to
title: "Operator CR Service Onboarding"
audience: "platform engineers, cluster operators"
tags: [operators, custom-resources, overlays, fluxcd, onboarding]
---

# Operator CR Service Onboarding

**Purpose:** For platform engineers and cluster operators, explains how to onboard services where the operator is installed with Helm and the actual workload is created by operator-managed custom resources from the cluster overlay repo.

Use this guide for patterns such as:

- `strimzi-kafka-operator` followed by `Kafka`, `KafkaTopic`, and `KafkaUser`
- `postgres-operator` followed by `postgresql`

## When To Use This Guide

Use this guide when:

- The operator itself is installed with `HelmRelease`
- The cluster overlay repo must create the workload using custom resources

If the service is a standard Helm application such as `cert-manager`, `harbor`, `longhorn`, `metallb`, or `loki`, use [Helm Service Onboarding](helm-service-onboarding.md).

---

## Workflow Summary

The path examples below use a common cluster-repo layout where service activation lives under `applications/overlays/<cluster>/services/`. If your cluster repository uses a different root, keep the same split between `sources/`, `fluxcd/`, and cluster-local operator workload content in the equivalent location.

1. Choose the source repo using [Service Deployment Patterns](service-deployment-patterns.md)
2. Install the operator from the selected source repo
3. Create a cluster-local overlay for the operator-managed custom resources
4. Ensure the custom-resource overlay depends on the operator installation
5. Validate both the operator and the workload custom resources

---

## Step 1: Confirm The Operator Is Helm-Installed

Check the base service under:

```text
applications/base/services/<service>/
```

You are looking for:

- `helmrelease.yaml`
- Chart source configuration

Typical operator services in this repo:

- `applications/base/services/strimzi-kafka-operator/`
- `applications/base/services/postgres-operator/`

---

## Step 2: Install The Operator

In the cluster overlay repo, using the common layout shown in these examples:

1. Create the source object under `applications/overlays/<cluster>/services/sources/`
2. Register it from `services/sources/kustomization.yaml`
3. Create the operator install `Kustomization` under `applications/overlays/<cluster>/services/fluxcd/<service>.yaml`
4. Register it from `services/fluxcd/kustomization.yaml`

Use the correct source path:

- Community: `./applications/base/services/<service>`
- Enterprise: `./applications/enterprise/services/<service>/overlays/install`

If the enterprise repo is used, the cluster repo must also provide the required Git and registry credentials.

If `services/fluxcd/kustomization.yaml` does not include `<service>.yaml`, Flux will not apply the operator install `Kustomization`.

---

## Step 3: Create The Custom-Resource Overlay

Create a separate cluster-local overlay for the operator-managed workload. In the common layout used in these examples:

```text
applications/overlays/<cluster>/services/<service>/
```

This overlay should contain:

- The workload custom resources
- Secrets and SOPS-encrypted values required by those resources
- Storage, backup, networking, or exposure configuration
- Additional cluster-specific supporting manifests

Use `dependsOn` so the custom-resource overlay reconciles after the operator installation.

---

## Example: Kafka With Strimzi

`strimzi-kafka-operator` installs the operator. The cluster overlay then creates Kafka resources such as:

- `Kafka`
- `KafkaTopic`
- `KafkaUser`

The operator install is not the final application state. The actual Kafka service appears only after the cluster overlay applies those custom resources.

The Kafka workload activation is separate and usually comes from the cluster repo bootstrap source. In one real cluster overlay:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: kafka-cluster
  namespace: flux-system
spec:
  dependsOn:
    - name: strimzi-kafka-operator-base
      namespace: flux-system
  interval: 15m
  retryInterval: 1m
  timeout: 10m
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  path: ./applications/overlays/<cluster>/services/kafka-cluster
  targetNamespace: kafka-system
  prune: true
  wait: true
  commonMetadata:
    labels:
      app.kubernetes.io/part-of: kafka-cluster
      app.kubernetes.io/managed-by: flux
      opencenter/managed-by: opencenter
```

This shows the expected operator custom-resource pattern:

- the operator install and the Kafka workload are reconciled separately
- the Kafka workload depends on the Strimzi operator install
- the workload `Kustomization` in this example uses the cluster repo bootstrap source `flux-system`
- the workload manifests come from the cluster repo rather than the base service path

The `applications/overlays/<cluster>/services/kafka-cluster/` path would then contain the actual `Kafka`, `KafkaTopic`, `KafkaUser`, and supporting Secret manifests.

---

## Example: PostgreSQL With Postgres Operator

`postgres-operator` installs the Zalando operator. The cluster overlay then creates resources such as:

- `postgresql`
- Supporting Secrets for credentials
- Storage or backup configuration

Again, the workflow is two-stage:

1. Install the operator
2. Create the database workload from the cluster overlay repo

---

## Validation

Check the Flux resources first:

```bash
flux get sources git -n flux-system
flux get kustomizations -n flux-system
```

Then check the operator:

```bash
kubectl get helmreleases -A
kubectl get pods -n <operator-namespace>
```

Finally check the workload custom resources:

```bash
kubectl get <custom-resource-kind> -n <namespace>
kubectl describe <custom-resource-kind> <name> -n <namespace>
```

---

## Related Docs

- [Service Deployment Patterns](service-deployment-patterns.md)
- [Helm Service Onboarding](helm-service-onboarding.md)
- [OLM Service Onboarding](olm-service-onboarding.md)
- [Manage Secrets with SOPS](manage-secrets.md)
