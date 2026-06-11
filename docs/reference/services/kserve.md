---
id: service-kserve
title: "kserve"
sidebar_label: kserve
description: Reference for the KServe service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, ML platform teams"
tags: [kserve, inference, model-serving, ai]
---

# KServe

**Purpose:** For platform engineers, ML platform teams, documents the KServe service in openCenter-gitops-base.

`kserve` deploys the KServe controller and CRDs so AI/ML models can be served declaratively via InferenceService resources.

## What This Repo Deploys

- `Namespace/kserve`
- `HelmRelease/kserve-crd` (Custom Resource Definitions)
- `HelmRelease/kserve-resources` (controller, webhooks, runtimes)
- Base values Secret: `kserve-values-base`
- Optional override Secret: `kserve-values-override`

## When to Use It

- Predictive or generative AI models need to be served on Kubernetes with autoscaling.

## Example

```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: sklearn-iris
spec:
  predictor:
    model:
      modelFormat:
        name: sklearn
      storageUri: "gs://kfserving-examples/models/sklearn/1.0/model"
```

## Configuration Surfaces

- Service path: `applications/base/services/kserve/`
- Namespace: `kserve`
- Flux objects: `HelmRelease/kserve-crd`, `HelmRelease/kserve-resources`
- Source: `oci://ghcr.io/kserve/charts`

## Upstream References

- [KServe documentation](https://kserve.github.io/website/docs/intro)
- [KServe GitHub](https://github.com/kserve/kserve)
- [KServe Helm install guide](https://kserve.github.io/website/docs/install/kserve-install)
