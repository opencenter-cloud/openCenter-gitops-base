# Harbor – Base Configuration

This directory contains the **base manifests** for deploying [Harbor](https://goharbor.io/), a cloud-native registry that stores, signs, and scans container images and Helm charts.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/harbor.md).

The base values follow the same pattern as services like `cert-manager`:

- base values file: `helm-values/values-<version>.yaml`
- generated secret key: `values.yaml`
- cluster override secret key: `override.yaml`

**About Harbor:**

- Acts as a **secure and centralized container registry** for storing and managing OCI images and Helm charts.  
- Provides **role-based access control(RBAC)** and **OIDC authentication** for user and project management.  
- Supports **vulnerability scanning**, **image signing (Notary)**, and **content trust** to enhance supply chain security.  
- Integrates with **Trivy** for image vulnerability scanning and **ChartMuseum** for Helm chart management.  
- Can serve as a **private OCI registry** for GitOps workflows and Flux/Kustomize-based deployments.  
- Features an intuitive web UI, REST API, and CLI tools for efficient image lifecycle management.  
- Improves compliance, security, and performance for enterprise container environments.  

## Repository implementation

- Source path: `applications/base/services/harbor/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `harbor` and reads `harbor-values-base` plus the optional `harbor-values-override` Secret.
- Base values: `helm-values/values-1.19.2.yaml`; the chart source is declared in `source.yaml` and `catalog.yaml`.

> **Warning:** The active base values contain insecure placeholders: `externalURL` is `https://core.harbor.domain`, `harborAdminPassword` is `Harbor12345`, the internal database password is `changeit`, registry credentials are `harbor_registry_user`/`harbor_registry_password`, and `secretKey` is the static value `not-a-secure-key`. Both external exposure TLS (`expose.tls.enabled: false`) and internal TLS are disabled. Do not expose or promote this base unchanged; replace the hostname, credentials, and encryption key through the override Secret or `existingSecretSecretKey`, and configure TLS before use.

## Validation and limitations

Run `kustomize build applications/base/services/harbor/` to validate the local manifests. The base does not provide production database/object storage credentials, registry credentials, or external vulnerability-scanner configuration. It does provide the placeholder hostname and admin password called out above; replace those through cluster-specific values and secrets.
