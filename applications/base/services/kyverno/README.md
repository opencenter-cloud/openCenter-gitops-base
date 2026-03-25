# Kyverno - Base Configuration

This directory contains the **base manifests** for deploying [Kyverno](https://kyverno.io/), a Kubernetes-native policy engine used to enforce security, governance, and compliance policies as Kubernetes resources.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/kyverno.md).

## Public Repository Scope

- This public repository contains the **base** Kyverno assets backed by upstream public artifacts.
- If private chart sources, private registries, or enterprise-only changes are required, they should be applied from the **private enterprise repository** that consumes this base.

## Directory Layout

- `policy-engine/`: Helm-based Kyverno controller deployment base.
- `default-ruleset/`: Default policy ruleset resources.

## Kyverno

- Defines and enforces policies as Kubernetes-native resources.
- Validates, mutates, and generates resources through admission controls.
- Produces policy reports for compliance visibility.
- Commonly used to implement workload security and platform governance controls.
