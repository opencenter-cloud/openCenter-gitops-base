---
id: service-olm
title: "olm"
sidebar_label: olm
description: Reference for the Operator Lifecycle Manager service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [olm, operators, lifecycle]
---

# OLM

**Purpose:** For platform engineers, operators, documents the Operator Lifecycle Manager service in openCenter-gitops-base.

`olm` installs Operator Lifecycle Manager itself: the OLM API CRDs plus the controller, RBAC, service, and supporting resources from the upstream release manifests. It provides the machinery for installing other operators; this base does not install a workload operator merely by installing OLM.

## What This Repo Deploys

- upstream `crds.yaml` pinned to `v0.46.0`
- upstream `olm.yaml` pinned to `v0.46.0`
- the OLM controller resources rendered by `olm.yaml`, in the `olm` namespace where those resources are namespaced

## When to Use It

- The platform uses OLM-managed operators such as Keycloak.

## Example

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: keycloak-subscription
  namespace: keycloak
spec:
  name: keycloak-operator
  channel: fast
  installPlanApproval: Manual
  startingCSV: keycloak-operator.v26.4.2
  source: operatorhubio-catalog
  sourceNamespace: olm
```

## Configuration Surfaces

- Service path: `applications/base/services/olm/`
- Namespace: `olm`
- Deployment method: upstream static manifests

The catalog-derived service inventory reports OLM as `v0.34.0`, while the committed remote manifest URLs above pin the installed OLM resources to `v0.46.0`. This is manifest-versus-catalog metadata drift; the generated inventory remains catalog-derived. The base path does not create a workload operator's `CatalogSource`, `Subscription`, or `OperatorGroup`; those are consumer-owned. The example matches the committed Keycloak Subscription, which is a separate staged service that requires this OLM installation and a matching `operatorhubio-catalog` CatalogSource.

## Upstream References

- [OLM docs](https://olm.operatorframework.io/docs/)
- [OLM concepts](https://olm.operatorframework.io/docs/concepts/)
- [Operator Framework project](https://github.com/operator-framework/operator-lifecycle-manager)
