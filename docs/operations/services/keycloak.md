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

---

## Installation Flow

Keycloak in this repo is installed as a staged OLM-driven flow, not as a single Helm-based service.

The practical sequence is:

1. `00-postgres/` creates the backing PostgreSQL resources
2. `10-operator/` creates the OLM `OperatorGroup` and `Subscription`
3. OLM creates an `InstallPlan`
4. Because `installPlanApproval` is set to `Manual`, the pending `InstallPlan` must be approved from the cluster
5. After approval, OLM installs the Keycloak operator
6. `20-keycloak/` creates the `Keycloak` custom resource
7. `30-oidc-rbac/` can add optional RBAC resources

In the example cluster overlay repo, this staged flow is reflected in separate Flux `Kustomization` objects:

- `keycloak-postgres`
- `keycloak-operator`
- `keycloak-cr`

The `dependsOn` chain in the cluster overlay ensures PostgreSQL is applied first, then the operator stage, then the Keycloak custom resource stage.

---

## Manual InstallPlan Approval

The base Keycloak `Subscription` is configured with:

- `installPlanApproval: Manual`

That means the operator installation does **not** proceed automatically after Flux applies `10-operator/`.

This is set to `Manual` so operators can control when the OLM install or upgrade is applied. In practice, that gives the cluster team a chance to:

- Review the generated `InstallPlan`
- Make sure prerequisite resources such as PostgreSQL are ready
- Avoid an automatic operator change during an unsuitable maintenance window
- Approve the rollout only when the cluster is ready for it

After the `Subscription` is created, approve the pending `InstallPlan` manually from the cluster.

Typical workflow:

```bash
kubectl get subscription -n keycloak
kubectl get installplan -n keycloak
kubectl describe installplan <installplan-name> -n keycloak
kubectl patch installplan <installplan-name> -n keycloak --type merge -p '{"spec":{"approved":true}}'
```

If you want to review the full manifest before approval, use:

```bash
kubectl get installplan <installplan-name> -n keycloak -o yaml
```

Then verify that OLM continues the installation:

```bash
kubectl get csv -n keycloak
kubectl get pods -n keycloak
```

If the `InstallPlan` is not approved, the Keycloak operator will not be installed and the later `Keycloak` custom resource stage will not become ready.

---

## Common Cluster-Specific Configuration

Clusters usually need to decide:

- External hostname and TLS handling
- Database sizing and storage
- Instance count and HA requirements
- Ingress or gateway exposure pattern
- Realm bootstrap strategy
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

---

## Realm and Client Configuration

The base service does not fully bootstrap your tenant-specific realms and clients. Cluster repos usually add one or more of:

- `KeycloakRealmImport` resources
- Post-install jobs or automation for realm bootstrap
- Client definitions for platform services such as Headlamp or Grafana

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

---

## Dependencies

Keycloak in this repo depends on:

- `olm` for operator installation
- PostgreSQL resources from `00-postgres/`
- Manual approval of the OLM `InstallPlan`
- Ingress or gateway configuration for external access
- Optionally `rbac-manager` if `30-oidc-rbac/` is used

---

## Verification

```bash
kubectl get subscription -n keycloak
kubectl get installplan -n keycloak
kubectl get csv -n keycloak
kubectl get keycloak -n keycloak
kubectl get pods -n keycloak
kubectl logs -n keycloak deploy/keycloak-operator
```

Healthy signs:

- The pending `InstallPlan` has been approved
- OLM subscription and CSV are `Succeeded`
- `Keycloak` custom resource reports ready status
- External hostname serves the Keycloak login page

---

## Common Failure Modes

Operator never installs:
Check OLM health, catalog sources, the Keycloak subscription channel, and whether the `InstallPlan` is still waiting for manual approval.

Pods fail with DB connection errors:
Verify PostgreSQL service name, credentials, and storage readiness.

OIDC clients fail login:
Verify redirect URIs, client secrets, and external hostname configuration.

RBAC group bindings do not work:
Verify `rbac-manager` is installed and the cluster API server exposes the expected OIDC `groups` claim.

---

## Related Docs

- [Keycloak Service Reference](../../reference/services/keycloak.md)
