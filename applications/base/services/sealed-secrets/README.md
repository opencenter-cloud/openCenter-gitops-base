# Sealed Secrets – Base Configuration

This directory contains the **base manifests** for deploying [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), a Kubernetes controller and CLI tool that allows storing encrypted secrets safely in Git repositories.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/sealed-secrets.md).

**About Sealed Secrets:**

- Enables **GitOps-friendly secret management** by encrypting Kubernetes secrets into SealedSecrets, which can be safely committed to version control.  
- Uses a **controller running in the cluster** to decrypt SealedSecrets and generate standard Kubernetes Secrets.  
- Ensures that only the controller(with access to the private key) can decrypt the data, maintaining confidentiality even if the repository is public.  
- Supports both **namespace-scoped** and **cluster-wide** encryption keys.  
- Allows secret rotation and re-encryption without exposing sensitive values in plaintext.  
- Commonly used to manage credentials, API keys, and tokens securely in GitOps-managed clusters.  
- Simplifies secret management workflows while maintaining strong encryption and operational security.  

## Repository implementation

- Source path: `applications/base/services/sealed-secrets/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `sealed-secrets` and reads `sealed-secrets-values-base` plus the optional `sealed-secrets-values-override` Secret.
- Base values: `helm-values/values-2.20.0.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

## Validation and limitations

Run `kustomize build applications/base/services/sealed-secrets/` to validate the local manifests. Encryption keys are cluster state and are not supplied by this public base. Back up and protect the controller key before rotating or rebuilding a cluster; rendering manifests does not prove a SealedSecret can be decrypted.
