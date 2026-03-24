---
id: service-keycloak
title: "keycloak"
sidebar_label: keycloak
description: Reference for the Keycloak service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, security teams"
tags: [keycloak, oidc, iam]
---

# Keycloak

`keycloak` provides identity and access management for the platform. In this repository it is modeled as staged manifests for the PostgreSQL backing store, operator installation, Keycloak custom resource, and optional default OIDC RBAC.

## What This Repo Deploys

- `00-postgres/` for the PostgreSQL cluster resources
- `10-operator/` for OLM subscription and operator group
- `20-keycloak/` for the Keycloak custom resource
- `30-oidc-rbac/` for optional default RBAC definitions

## When to Use It

- You need a shared OIDC provider for dashboards, gateways, and internal platform apps.
- You want centralized user, group, and client management.
- You want to bind OIDC groups to Kubernetes roles through `rbac-manager`.

## Key Integration Points

- Headlamp, Grafana, Harbor, and gateway-facing apps often use Keycloak as their OIDC issuer.
- The optional `30-oidc-rbac` layer assumes `rbac-manager` is present.
- The Keycloak operator depends on OLM being installed and healthy.

## Example

```yaml
spec:
  hostname:
    hostname: auth.example.com
    strict: true
```

## Configuration Surfaces

- Service path: `applications/base/services/keycloak/`
- Namespace: `keycloak`
- Stages: `00-postgres/`, `10-operator/`, `20-keycloak/`, `30-oidc-rbac/`
- Deployment method: operator-managed Keycloak instance

## Related Docs

- [Keycloak Configuration Guide](../../how-to/services/keycloak.md)

## Upstream References

- [Keycloak documentation](https://www.keycloak.org/documentation)
- [Keycloak Operator guide](https://www.keycloak.org/operator/installation)
- [OIDC overview in Keycloak](https://www.keycloak.org/securing-apps/oidc-layers)
