# Alert-Proxy - Base Configuration

This directory contains the base manifests for deploying Alert Proxy. It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

## Public Repository Scope

- This public repository contains the base Alert Proxy deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the private enterprise repository that consumes this base.

## What This Base Includes

- `Namespace/rackspace`
- `HelmRepository/rackspace-charts`
- `HelmRelease/alert-proxy`
- base chart values from the service `helm-values/` directory

## Alert Proxy

- Aggregates and forwards alert traffic for Rackspace-managed integrations.
- Runs as a managed-service component separate from the core platform service catalog.
- Is typically consumed as part of a wider managed-service deployment model rather than as a standalone cluster feature.
