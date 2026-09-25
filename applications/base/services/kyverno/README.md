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

## Repository implementation

- Source path: `applications/base/services/kyverno/`.
- The controller entrypoint is `policy-engine/kustomization.yaml`; `default-ruleset/` is an optional policy layer and is not the controller itself.
- The policy-engine HelmRelease reads `policy-engine/helm-values/values-3.9.1.yaml` and the optional `kyverno-values-override` Secret.

## Validation and limitations

Run `kustomize build applications/base/services/kyverno/policy-engine/` and, when selected, `kustomize build applications/base/services/kyverno/default-ruleset/`. The controller base does not automatically enable every policy in the repository, and admission behavior depends on the ruleset, policy mode, and workload labels selected by the consuming overlay.
