---
id: sops-configuration
title: "SOPS Configuration Reference"
sidebar_label: SOPS Configuration
description: SOPS and secret-encryption boundaries in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers"
tags: [sops, encryption, secrets, age, kubernetes]
---

# SOPS Configuration Reference

**Purpose:** Records the SOPS-related state of `openCenter-gitops-base` and the boundary between this base repository and consuming cluster repositories.

**Type:** Reference  
**Audience:** Platform engineers  
**Last Updated:** 2026-09-25

## Repository State

There is no committed `.sops.yaml`, encrypted manifest, age key, or Flux `Kustomization.spec.decryption` configuration in this repository. SOPS decryption is therefore **not implemented by the base service paths**.

The base repository does contain the following secret-related mechanisms:

- Helm values are packaged into generated Kubernetes Secrets by service-local Kustomize `secretGenerator` entries.
- Helm releases may consume an optional `*-values-override` Secret through `valuesFrom`.
- `sealed-secrets` is a separate, committed service and is documented in [its service reference](services/sealed-secrets.md).

Generated values Secrets are configuration artifacts, not a replacement for encrypting sensitive consumer values before they are committed.

## Consumer Repository Boundary

Cluster or private consumer repositories own encrypted overrides, age key storage, and Flux decryption settings when they choose SOPS. They must provide any required `Kustomization.spec.decryption` configuration and the referenced key Secret; no such Secret is created here.

For example, a consumer may add a Flux decryption block to its own Kustomization:

```yaml
spec:
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

This is a **consumer-side pattern**, not a resource currently rendered by this repository. The key Secret name, age recipients, `.sops.yaml` rules, and encrypted paths are consumer-owned and must not be inferred from the base service paths.

## What Is Not Implemented Here

- No repository-wide SOPS policy is committed.
- No age recipient is configured for base services.
- No base Kustomization decrypts SOPS files.
- No private or enterprise key material is stored in this repository.

These items may be added by a consuming repository, but doing so is outside the base service contract.

## Choosing a Secret Mechanism

Use the mechanism that matches the ownership boundary:

| Mechanism | Current base-repo status | Decryption owner |
|---|---|---|
| SOPS with age | Consumer-side option; no base configuration | Flux Kustomize controller, configured by the consumer |
| Sealed Secrets | Deployable base service | Sealed Secrets controller in the target cluster |
| Helm `valuesFrom` override | Supported interface on Helm releases that declare it | Consuming cluster repository creates the override Secret |

## Validation Boundary

This repository cannot validate consumer-owned SOPS recipients, encrypted files, or cluster key Secrets because none are committed here. Validate those items in the consuming repository with its configured SOPS and Flux tooling.

Never commit private keys or plaintext credentials to either repository.
