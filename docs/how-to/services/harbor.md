---
id: harbor-config-guide
title: "Harbor Configuration Guide"
sidebar_label: Harbor
description: How to configure Harbor in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [harbor, registry, containers, kubernetes]
---

# Harbor Configuration Guide

Use this guide when a cluster repo needs to customize the Harbor deployment shipped in `applications/base/services/harbor/`.

## What the Base Deploys

The base service deploys:

- the `harbor` namespace
- a Harbor Helm repository source
- `HelmRelease/harbor`
- base chart values from the service `helm-values/` directory

The `HelmRelease` reads:

- `Secret/harbor-values-base` with key `values.yaml`
- optional `Secret/harbor-values-override` with key `override.yaml`

## Common Cluster-Specific Configuration

Most clusters need to set:

- external hostname and ingress/gateway exposure
- TLS secret names and certificate source
- persistent storage classes and sizes for registry, jobservice, Redis, and database if internal components are used
- external database and Redis endpoints if Harbor is not self-contained
- OIDC / SSO settings
- scanner and retention settings

## Override Values Pattern

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: harbor

secretGenerator:
  - name: harbor-values-override
    files:
      - override.yaml=override.yaml
    options:
      disableNameSuffixHash: true
```

Example `override.yaml`:

```yaml
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: harbor-tls
  ingress:
    hosts:
      core: harbor.example.com

persistence:
  persistentVolumeClaim:
    registry:
      storageClass: longhorn-general
      size: 200Gi

externalURL: https://harbor.example.com
```

## External Dependencies

Depending on your operating model, Harbor may also need:

- external PostgreSQL
- external Redis
- object storage for large-scale registry storage
- OIDC provider configuration

Those supporting credentials usually live in cluster-local Secrets referenced from override values.

## Verification

```bash
kubectl get pods -n harbor
kubectl get helmrelease -n harbor harbor
kubectl get ingress -n harbor
kubectl logs -n harbor deploy/harbor-core
```

Healthy signs:

- `HelmRelease/harbor` is `Ready=True`
- core, registry, jobservice, and portal Pods are `Running`
- Harbor UI and API respond on the configured hostname

## Common Failure Modes

Pods fail to start with DB errors:
- verify external database hostname, credentials, and TLS expectations

Image pushes fail:
- check ingress or gateway upload limits and registry storage health

OIDC login fails:
- verify redirect URIs, client secret, and external URL settings

Scanner issues:
- check Trivy updater connectivity and storage for vulnerability DB content

## Related Docs

- [Harbor Service Reference](../../reference/services/harbor.md)
