---
id: service-cert-manager
title: "cert-manager"
sidebar_label: cert-manager
description: Reference for the cert-manager service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [cert-manager, tls, certificates]
---

# cert-manager

`cert-manager` automates certificate issuance and renewal for Kubernetes workloads. In this repository it is deployed as a Flux-managed Helm release in the `cert-manager` namespace.

## What This Repo Deploys

- A `Namespace/cert-manager`
- A `HelmRepository/jetstack`
- A `HelmRelease/cert-manager`
- Base chart values from the service `helm-values/` directory
- An optional override Secret named `cert-manager-values-override`

## When to Use It

- You need automated TLS for ingress, Gateway API, or internal services.
- You want ACME, Vault, Venafi, or private PKI integration through Kubernetes resources.
- You want certificates renewed and rotated through GitOps rather than manual scripting.

## Key Integration Points

- `gateway-api`, ingress controllers, and service meshes consume the generated TLS Secrets.
- Cluster repos usually add `Issuer`, `ClusterIssuer`, and `Certificate` resources.
- DNS providers or ACME solvers usually require additional credentials in the cluster repo.

## Example Resource

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: platform@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

## Configuration Surfaces

- Service path: `applications/base/services/cert-manager/`
- Namespace: `cert-manager`
- Flux object: `HelmRelease/cert-manager`
- Base values Secret: `cert-manager-values-base`
- Override values Secret: `cert-manager-values-override`
- Source: Jetstack Helm repository

## Related Docs

- [Cert-manager Configuration Guide](../../how-to/services/cert-manager.md)
- [Gateway API Reference](gateway-api.md)

## Upstream References

- [cert-manager documentation](https://cert-manager.io/docs/)
- [Jetstack Helm chart](https://artifacthub.io/packages/helm/cert-manager/cert-manager)
- [ACME issuer reference](https://cert-manager.io/docs/configuration/acme/)
