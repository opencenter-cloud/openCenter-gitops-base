# Kyverno - Base Configuration

This directory contains the **base manifests** for deploying [Kyverno](https://kyverno.io/), a Kubernetes-native policy engine that helps enforce best practices, security, and compliance through policies defined as Kubernetes resources.
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For the parent service overview, use cases, examples, and upstream references, see the [Kyverno service reference](../../../../../docs/reference/services/kyverno.md).

## Public Repository Scope

- This public repository contains the **base** Kyverno policy engine deployment backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Kyverno

- Allows defining and enforcing **policies as Kubernetes resources** without requiring custom programming or external policy languages.
- Enables automatic configuration management, for example injecting labels, enforcing naming conventions, or setting security contexts.
- Integrates with **Admission Webhooks** to evaluate policies in real time during resource creation or modification.
- Provides **policy reports** and integrates with tools like **Prometheus** and **Grafana** for monitoring violations.
- Commonly used to implement governance, security, and multi-tenancy controls in Kubernetes clusters.
- Simplifies cluster compliance and enhances operational security through policy-driven automation.
