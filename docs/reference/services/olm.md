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

`olm` installs Operator Lifecycle Manager so cluster operators can manage other operators using `CatalogSource`, `Subscription`, and `OperatorGroup` resources.

## What This Repo Deploys

- upstream `crds.yaml` pinned to `v0.34.0`
- upstream `olm.yaml` pinned to `v0.34.0`

## When to Use It

- The platform uses OLM-managed operators such as Keycloak.

## Example

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: my-operator
  namespace: operators
spec:
  channel: stable
  source: community-operators
  sourceNamespace: olm
```

## Configuration Surfaces

- Service path: `applications/base/services/olm/`
- Namespace: `olm`
- Deployment method: upstream static manifests

## Upstream References

- [OLM docs](https://olm.operatorframework.io/docs/)
- [OLM concepts](https://olm.operatorframework.io/docs/concepts/)
- [Operator Framework project](https://github.com/operator-framework/operator-lifecycle-manager)
