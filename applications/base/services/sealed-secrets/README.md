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
