# Keycloak - Base Configuration

This directory contains the **base manifests** for deploying [Keycloak](https://www.keycloak.org/), an IAM solution for authentication, authorization, and OIDC/SAML-based SSO.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/keycloak.md).

## Public Repository Scope

- This public repository contains the **base** Keycloak deployment backed by upstream public artifacts.
- If private image rewrites, private catalog sources, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Stage Layout

- `00-postgres/`: PostgreSQL backing database resources.
- `10-operator/`: OLM operator group and subscription resources.
- `20-keycloak/`: Keycloak custom resource.
- `30-oidc-rbac/`: Optional default OIDC RBAC resources.
