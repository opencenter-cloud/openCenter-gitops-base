---
id: service-nodelocaldns
title: "nodelocaldns"
sidebar_label: nodelocaldns
description: Reference for the nodelocaldns service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators"
tags: [dns, caching, performance, daemonset, coredns]
---

# NodeLocal DNS Cache

**Purpose:** For platform engineers, operators, documents the nodelocaldns service in openCenter-gitops-base.

`nodelocaldns` deploys a DNS caching agent on every cluster node to reduce DNS lookup latency and improve reliability by avoiding conntrack race conditions.

## What This Repo Deploys

- HelmRepository `nodelocaldns` pointing to `https://lablabs.github.io/k8s-nodelocaldns-helm/`
- HelmRelease `nodelocaldns` deploying chart version `2.4.0` into `kube-system`
- Base Helm values via `nodelocaldns-values-base` Secret

## When to Use It

- Your cluster experiences DNS lookup latency or intermittent DNS resolution failures.
- You want to reduce load on CoreDNS by caching DNS responses locally on each node.
- You need to avoid conntrack table overflow issues with UDP DNS traffic.
- You are running workloads that perform frequent DNS lookups.

## Example

```yaml
# Cluster overlay override to customise upstream DNS
apiVersion: v1
kind: Secret
metadata:
  name: nodelocaldns-values-override
  namespace: kube-system
type: Opaque
stringData:
  override.yaml: |
    config:
      localDnsIp: 169.254.20.11
      zones:
        - zone: "cluster.local"
          plugins:
            - name: forward
              parameters: . __PILLAR__CLUSTER__DNS__ { force_tcp }
```

## Configuration Surfaces

- Service path: `applications/base/services/nodelocaldns/`
- Namespace: `kube-system`
- Deployment method: Helm chart via Flux HelmRelease
- Base values: `helm-values/values-2.4.0.yaml`
- Override mechanism: optional `nodelocaldns-values-override` Secret in `nodelocaldns`

## Upstream References

- [NodeLocal DNS Cache Helm chart](https://github.com/lablabs/k8s-nodelocaldns-helm)
- [Kubernetes NodeLocal DNS Cache documentation](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/)
- [KEP: NodeLocal DNS Cache](https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/1024-nodelocal-cache-dns/README.md)
