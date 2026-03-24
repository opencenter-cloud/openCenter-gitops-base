---
id: cert-manager-config-guide
title: "Cert-manager Configuration Guide"
sidebar_label: Cert-manager
description: How to configure cert-manager in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [cert-manager, tls, certificates, kubernetes]
---

# Cert-manager Configuration Guide

Use this guide when a cluster repo needs to customize `cert-manager` beyond the base deployment shipped in `applications/base/services/cert-manager/`.

## What the Base Deploys

The base service deploys:

- the `cert-manager` namespace
- the Jetstack Helm repository source
- `HelmRelease/cert-manager`
- base chart values from the service `helm-values/` directory

The base `HelmRelease` reads:

- `Secret/cert-manager-values-base` using key `values.yaml`
- optional `Secret/cert-manager-values-override` using key `override.yaml`

That means cluster-specific Helm changes belong in `cert-manager-values-override`, while issuers and certificate resources usually live as separate manifests in the cluster repo.

## Common Cluster-Specific Configuration

Most clusters need to decide:

- how external certificates are issued: `http01`, `dns01`, or an internal CA
- which ingress or gateway class solves ACME challenges
- whether `installCRDs` stays enabled in the chart
- resource requests and limits for the controller, webhook, and cainjector
- Pod Security / NetworkPolicy adjustments if the cluster enforces them

## Override Values Pattern

The typical cluster-repo pattern is to generate `cert-manager-values-override`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: cert-manager

secretGenerator:
  - name: cert-manager-values-override
    files:
      - override.yaml=override.yaml
    options:
      disableNameSuffixHash: true
```

Example `override.yaml`:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    memory: 512Mi

webhook:
  timeoutSeconds: 10

cainjector:
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
```

## Issuers and Certificates

Helm values configure the controller itself. Issuers and certificates are separate Kubernetes resources and should usually live in the cluster repo:

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

Use `dns01` instead of `http01` when:

- wildcard certificates are required
- the service is not reachable from the public internet during validation
- you are issuing certificates for internal-only DNS names

## Supporting Secrets and Credentials

The base repo does not create provider credentials. Cluster repos usually add them, for example:

- DNS provider API tokens for `dns01`
- Vault tokens or Kubernetes auth configuration for Vault issuers
- CA private keys or intermediate issuer material for private PKI

## Verification

```bash
kubectl get pods -n cert-manager
kubectl get helmrelease -n cert-manager cert-manager
kubectl get clusterissuer
kubectl get certificaterequest -A
kubectl describe certificate <name> -n <namespace>
```

Healthy signs:

- controller, webhook, and cainjector Pods are `Running`
- `HelmRelease/cert-manager` is `Ready=True`
- `Issuer` or `ClusterIssuer` resources report `Ready=True`
- created TLS Secrets exist in the expected application namespaces

## Common Failure Modes

`Certificate` stays pending:
- inspect the related `CertificateRequest`, `Order`, or `Challenge`

`http01` challenge fails:
- verify the ingress/gateway class and that `/.well-known/acme-challenge/` is routable

`dns01` challenge fails:
- verify provider credentials, zone access, and the exact DNS zone name

Webhook timeouts or admission failures:
- check the cert-manager webhook Pod and confirm the cluster can resolve and reach the webhook service

## Related Docs

- [cert-manager Service Reference](../../reference/services/cert-manager.md)
- [Gateway API Reference](../../reference/services/gateway-api.md)
