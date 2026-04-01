---
id: olm-service-onboarding
sidebar_label: OLM Service Onboarding
description: Step-by-step guide for onboarding services that install their operator through OLM into a cluster overlay repo.
doc_type: how-to
title: "OLM Service Onboarding"
audience: "platform engineers, cluster operators"
tags: [olm, operators, overlays, fluxcd, onboarding]
---

# OLM Service Onboarding

**Purpose:** For platform engineers and cluster operators, explains how to onboard services whose operator is installed through OLM resources such as `OperatorGroup` and `Subscription`.

Use this guide for services such as `keycloak`, where the base service includes OLM resources and then creates operator-managed custom resources.

## When To Use This Guide

Use this guide when the base service contains OLM resources such as:

- `OperatorGroup`
- `Subscription`

If the operator is installed with `HelmRelease` and the cluster overlay later creates custom resources such as `Kafka` or `postgresql`, use [Operator CR Service Onboarding](operator-cr-service-onboarding.md) instead.

---

## Workflow Summary

The path examples below use a common cluster-repo layout where service activation lives under `applications/overlays/<cluster>/services/`. If your cluster repository uses a different root, keep the same split between `sources/`, `fluxcd/`, and cluster-local service content in the equivalent location.

1. Choose the source repo using [Service Deployment Patterns](service-deployment-patterns.md)
2. Add the source object and install `Kustomization` in the cluster overlay repo
3. Allow OLM to install and settle the operator
4. Add cluster-local patches, custom resources, and supporting manifests
5. Validate the OLM resources, operator, and managed custom resources

---

## Step 1: Confirm The Service Uses OLM

Check the base service under:

```text
applications/base/services/<service>/
```

You are looking for files such as:

- `operatorgroup.yaml`
- `subscription.yaml`

For example, `keycloak` uses a staged structure:

```text
applications/base/services/keycloak/
├── 00-postgres/
├── 10-operator/
├── 20-keycloak/
└── 30-oidc-rbac/
```

---

## Step 2: Add The Source And Install Path

In the cluster overlay repo, using the common layout shown in these examples:

1. Create the source object under `applications/overlays/<cluster>/services/sources/`
2. Register it from `services/sources/kustomization.yaml`
3. Create the install `Kustomization` under `applications/overlays/<cluster>/services/fluxcd/<service>.yaml`
4. Register it from `services/fluxcd/kustomization.yaml`

Use the correct source path:

- Community: `./applications/base/services/<service>`
- Enterprise: `./applications/enterprise/services/<service>/overlays/install`

If the enterprise repo is used, the cluster repo must also provide the required Git and registry credentials.

If `services/fluxcd/kustomization.yaml` does not include `<service>.yaml`, Flux will not apply the service install `Kustomization`.

---

## Step 3: Let OLM Install The Operator

After Flux applies the service manifests:

- OLM reads the `Subscription`
- OLM installs the operator and its CSV
- The operator becomes available in the target namespace

Do not expect the service custom resources to become ready until the OLM installation is healthy.

---

## Step 4: Add Cluster-Local Resources

Create the cluster-local overlay in the directory that holds service-specific cluster content. In the common layout used in these examples:

```text
applications/overlays/<cluster>/services/<service>/
```

This overlay should contain cluster-specific resources such as:

- Custom resource patches
- Ingress, gateway, or route objects
- Realm bootstrap or client resources
- Secrets and SOPS-encrypted values
- RBAC integration or supporting manifests

For routine cluster changes, edit only the cluster overlay repo.

---

## Example: Keycloak

For `keycloak`, the practical cluster workflow is:

1. Install the base service from the selected source repo
2. Wait for the OLM operator installation to settle
3. Patch or extend the `Keycloak` custom resource from the cluster overlay

Typical cluster-local patch target:

```yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak
  namespace: keycloak
spec:
  instances: 2
  hostname:
    hostname: auth.example.com
    strict: true
  http:
    tlsSecret: keycloak-tls
```

For service-specific guidance, see [Keycloak Configuration Guide](services/keycloak.md).

---

## Validation

Check the Flux resources first:

```bash
flux get sources git -n flux-system
flux get kustomizations -n flux-system
```

Then verify OLM:

```bash
kubectl get subscription -n <namespace>
kubectl get csv -n <namespace>
kubectl get pods -n <namespace>
```

Finally verify the custom resources:

```bash
kubectl get <custom-resource-kind> -n <namespace>
kubectl describe <custom-resource-kind> <name> -n <namespace>
```

---

## Related Docs

- [Service Deployment Patterns](service-deployment-patterns.md)
- [Operator CR Service Onboarding](operator-cr-service-onboarding.md)
- [Keycloak Configuration Guide](services/keycloak.md)
- [Manage Secrets with SOPS](manage-secrets.md)
