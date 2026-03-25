---
id: keycloak-config-guide
title: "Keycloak Configuration Guide"
sidebar_label: Keycloak
description: How to configure the staged Keycloak deployment in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [keycloak, authentication, iam, kubernetes]
---

# Keycloak Configuration Guide

Use this guide when a cluster repo needs to adapt the staged Keycloak deployment in `applications/base/services/keycloak/`.

## Service Layout in This Repo

The base service is intentionally split into stages:

- `00-postgres/` creates the backing PostgreSQL resources
- `10-operator/` installs the Keycloak operator through OLM
- `20-keycloak/` creates the `Keycloak` custom resource
- `30-oidc-rbac/` adds optional default OIDC RBAC definitions

Most cluster-specific customization happens by patching the Keycloak custom resource or by layering additional realm, client, and ingress resources in the cluster repo.

## Common Cluster-Specific Configuration

Clusters usually need to decide:

- external hostname and TLS handling
- database sizing and storage
- instance count and HA requirements
- ingress / gateway exposure pattern
- realm bootstrap strategy
- OIDC clients for Headlamp, Grafana, Harbor, and application workloads

## Example Keycloak Patch

```yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak
  namespace: keycloak
spec:
  instances: 2
  hostname:
    hostname: auth.example.com
    strict: true
  http:
    tlsSecret: keycloak-tls
```

Apply patches from the cluster repo against `20-keycloak/keycloak-cr.yaml` rather than editing the base.

## Realm and Client Configuration

The base service does not fully bootstrap your tenant-specific realms and clients. Cluster repos usually add one or more of:

- `KeycloakRealmImport` resources
- post-install jobs or automation for realm bootstrap
- client definitions for platform services such as Headlamp or Grafana

Example:

```yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: KeycloakRealmImport
metadata:
  name: opencenter
  namespace: keycloak
spec:
  keycloakCRName: keycloak
  realm:
    realm: opencenter
    enabled: true
```

## Dependencies

Keycloak in this repo depends on:

- `olm` for operator installation
- PostgreSQL resources from `00-postgres/`
- ingress or gateway configuration for external access
- optionally `rbac-manager` if `30-oidc-rbac/` is used

## Verification

```bash
kubectl get subscription -n keycloak
kubectl get csv -n keycloak
kubectl get keycloak -n keycloak
kubectl get pods -n keycloak
kubectl logs -n keycloak deploy/keycloak-operator
```

Healthy signs:

- OLM subscription and CSV are `Succeeded`
- `Keycloak` custom resource reports ready status
- external hostname serves the Keycloak login page

## Common Failure Modes

Operator never installs:
- check OLM health, catalog sources, and the Keycloak subscription channel

Pods fail with DB connection errors:
- verify PostgreSQL service name, credentials, and storage readiness

OIDC clients fail login:
- verify redirect URIs, client secrets, and external hostname configuration

RBAC group bindings do not work:
- verify `rbac-manager` is installed and the cluster API server exposes the expected OIDC `groups` claim

## Related Docs

- [Keycloak Service Reference](../../reference/services/keycloak.md)
