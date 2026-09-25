---
id: service-nodelocaldns
title: "nodelocaldns"
sidebar_label: nodelocaldns
description: Reference for the NodeLocal DNS Cache service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, network teams"
tags: [dns, cache, nodelocal, networking]
---

# NodeLocal DNS Cache

**Purpose:** For platform engineers, network teams, documents the NodeLocal DNS Cache service in openCenter-gitops-base.

`nodelocaldns` deploys a per-node DNS caching agent that improves DNS performance and avoids conntrack race conditions.

## What This Repo Deploys

- `Namespace/nodelocaldns`
- `HelmRelease/nodelocaldns`
- Base values Secret: `nodelocaldns-values-base`
- Optional override Secret: `nodelocaldns-values-override`

## When to Use It

- DNS latency is a concern or conntrack table exhaustion affects DNS reliability.

## Example

```yaml
# The committed base values use these settings; override values are consumer-owned.
image:
  tag: "1.23.1"
config:
  localDnsIp: 169.254.20.11
```

## Configuration Surfaces

- Service path: `applications/base/services/nodelocaldns/`
- Namespace: `nodelocaldns`
- Flux object: `HelmRelease/nodelocaldns`
- Source: `https://lablabs.github.io/k8s-nodelocaldns-helm/`
- Chart version: `2.4.0`

The base values set image tag `1.23.1`, local DNS IP `169.254.20.11`, and resource requests of `30m` CPU and `50Mi` memory. The local DNS IP must be compatible with the cluster's DNS and node configuration; this repository does not validate that cluster-specific choice.

## Upstream References

- [k8s-nodelocaldns-helm GitHub](https://github.com/lablabs/k8s-nodelocaldns-helm)
- [NodeLocal DNSCache Kubernetes docs](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/)
