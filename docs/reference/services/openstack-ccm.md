---
id: service-openstack-ccm
title: "openstack-ccm"
sidebar_label: openstack-ccm
description: Reference for the OpenStack Cloud Controller Manager service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [openstack, ccm, cloud-provider]
---

# OpenStack CCM

`openstack-ccm` integrates Kubernetes with OpenStack APIs for node metadata, routes, and load balancer services.

## What This Repo Deploys

- `Namespace/openstack-ccm` with privileged Pod Security labels
- `HelmRelease/openstack-cloud-controller-manager`
- Base values Secret: `openstack-ccm-values-base`
- Optional override Secret: `openstack-ccm-values-override`

## When to Use It

- The cluster runs on OpenStack and expects cloud-provider integration.

## Example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  type: LoadBalancer
```

## Configuration Surfaces

- Service path: `applications/base/services/openstack-ccm/`
- Namespace: `openstack-ccm`
- Flux object: `HelmRelease/openstack-cloud-controller-manager`
- Source: Kubernetes cloud-provider-openstack Helm repository

## Upstream References

- [Cloud Provider OpenStack docs](https://github.com/kubernetes/cloud-provider-openstack/tree/master/docs)
- [OpenStack CCM chart docs](https://github.com/kubernetes/cloud-provider-openstack/tree/master/charts/openstack-cloud-controller-manager)
