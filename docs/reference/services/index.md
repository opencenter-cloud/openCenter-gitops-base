---
id: service-reference-library
title: "Service Reference Library"
sidebar_label: Service References
description: Per-service reference pages for all deployable platform services in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, architects"
tags: [services, reference, catalog, kubernetes]
---

# Service Reference Library

**Purpose:** For platform engineers, operators, and architects, documents the committed per-service reference pages for selected deployable platform services in openCenter-gitops-base.

This section provides reference pages for the services listed below. The repository catalog is broader than this page set: services without a page here remain catalog entries, not undocumented guarantees of this reference library. Each page summarizes only the repository facts supported by the corresponding manifests, values, catalog entry, or service README.

The pages describe base-repository interfaces. Cluster overlays, private enterprise components, credentials, external backends, and workload resources remain consumer-owned unless a page explicitly says the base path commits them.

## Core Services

- [cert-manager](cert-manager.md)
- [ceph-csi](ceph-csi.md)
- [external-snapshotter](external-snapshotter.md)
- [gateway-api](gateway-api.md)
- [harbor](harbor.md)
- [headlamp](headlamp.md)
- [istio](istio.md)
- [keycloak](keycloak.md)
- [kserve](kserve.md)
- [kyverno](kyverno.md)
- [longhorn](longhorn.md)
- [metallb](metallb.md)
- [mlflow-operator](mlflow-operator.md)
- [nodelocaldns](nodelocaldns.md)
- [nvidia-gpu-operator](nvidia-gpu-operator.md)
- [olm](olm.md)
- [openstack-ccm](openstack-ccm.md)
- [openstack-csi](openstack-csi.md)
- [postgres-operator](postgres-operator.md)
- [rbac-manager](rbac-manager.md)
- [sealed-secrets](sealed-secrets.md)
- [strimzi-kafka-operator](strimzi-kafka-operator.md)
- [triton-inference-server](triton-inference-server.md)
- [velero](velero.md)
- [vsphere-csi](vsphere-csi.md)

## CNI Services

- [calico](calico.md)
- [cilium](cilium.md)
- [kube-ovn](kube-ovn.md)

## Observability Services

- [kube-prometheus-stack](kube-prometheus-stack.md)
- [loki](loki.md)
- [mimir](mimir.md)
- [opentelemetry-kube-stack](opentelemetry-kube-stack.md)
- [tempo](tempo.md)
