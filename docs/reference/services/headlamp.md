---
id: service-headlamp
title: "headlamp"
sidebar_label: headlamp
description: Reference for the Headlamp service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, developers"
tags: [headlamp, dashboard, kubernetes-ui]
---

# Headlamp

`headlamp` is a web UI for browsing and operating Kubernetes clusters. In this repository it is packaged as a Helm release and commonly paired with OIDC and RBAC.

## What This Repo Deploys

- `Namespace/headlamp`
- `HelmRelease/headlamp`
- Base values Secret: `headlamp-values-base`
- Optional override Secret: `headlamp-values-override`

## When to Use It

- You want a cluster dashboard with a lighter operational footprint than the Kubernetes Dashboard.
- You want UI-based access paired with OIDC and Kubernetes RBAC.

## Key Integration Points

- Keycloak or another OIDC provider usually handles login.
- `rbac-manager` or native RBAC defines what users can see and do.

## Example

```yaml
config:
  oidc:
    clientID: headlamp
    issuerURL: https://auth.example.com/realms/opencenter
    callbackURL: https://headlamp.example.com/oidc-callback
```

## Configuration Surfaces

- Service path: `applications/base/services/headlamp/`
- Namespace: `headlamp`
- Flux object: `HelmRelease/headlamp`
- Source: Kubernetes SIGs Headlamp Helm repository

## Upstream References

- [Headlamp docs](https://headlamp.dev/docs/latest/)
- [Headlamp project site](https://headlamp.dev/)
- [Headlamp Helm chart](https://artifacthub.io/packages/helm/headlamp/headlamp)
