---
id: service-harbor
title: "harbor"
sidebar_label: harbor
description: Reference for the Harbor service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, security teams"
tags: [harbor, registry, images]
---

# Harbor

**Purpose:** For platform engineers, operators, security teams, documents the Harbor service in openCenter-gitops-base.

`harbor` provides a private OCI registry for container images and Helm charts. In this repository it is packaged as a Helm release in the `harbor` namespace.

## What This Repo Deploys

- A `Namespace/harbor`
- A Helm repository source for Harbor
- `HelmRelease/harbor`
- Base values from the service `helm-values/` directory
- An optional override Secret named `harbor-values-override`

## When to Use It

- You need an internal registry for application images or OCI Helm charts.
- You want project-level RBAC, image scanning, and artifact retention inside the platform.
- You need a stable registry endpoint for disconnected or partially connected environments.

## Key Integration Points

- Platform image pull secrets usually point workloads at Harbor projects.
- OIDC integration often uses Keycloak or another external identity provider.
- Persistent storage, ingress, and external database settings are usually cluster-specific.

## Example

```bash
docker login harbor.example.com
docker tag myapp:1.0 harbor.example.com/platform/myapp:1.0
docker push harbor.example.com/platform/myapp:1.0
```

## Configuration Surfaces

- Service path: `applications/base/services/harbor/`
- Namespace: `harbor`
- Flux object: `HelmRelease/harbor`
- Base values Secret: `harbor-values-base`
- Override values Secret: `harbor-values-override`
- Source: Harbor Helm repository
- Source URL: `https://helm.goharbor.io`
- Chart version: `1.19.2`

> **Important base-value warning:** The committed values are development defaults, not production credentials or endpoint configuration. Harbor currently uses `expose.type: clusterIP`, disables TLS, and carries the placeholder ingress hostname `core.harbor.domain`. The values also contain the Harbor admin password `Harbor12345`, registry credentials `harbor_registry_user` / `harbor_registry_password`, internal database password `changeit`, and static encryption key `secretKey: "not-a-secure-key"`. Before exposing or using Harbor, a consumer must provide an override Secret with a real hostname, TLS configuration, credentials, and a replacement encryption key (or configure `existingSecretSecretKey`); consumers must not rely on these committed defaults.

The example endpoint is illustrative and must be replaced by a consumer-owned hostname. Persistent storage, ingress, external database/object storage settings, credentials, and project image-pull Secrets remain consumer-owned; use `harbor-values-override` to change the base values.

## Related Docs

- [Harbor Configuration Guide](../../operations/services/harbor.md)

## Upstream References

- [Harbor documentation](https://goharbor.io/docs/)
- [Harbor Helm chart](https://artifacthub.io/packages/helm/harbor/harbor)
- [Harbor API reference](https://container-registry.com/docs/harbor-api-client/introduction/)
