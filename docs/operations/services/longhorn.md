---
id: longhorn-config-guide
title: "Longhorn Configuration Guide"
sidebar_label: Longhorn
description: How to configure Longhorn in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [longhorn, storage, kubernetes]
---

# Longhorn Configuration Guide

Use this guide when a cluster repo needs to adapt the Longhorn deployment or the storage classes shipped by the base repo.

## What the Base Deploys

The base service deploys:

- `Namespace/longhorn-system`
- `HelmRelease/longhorn`
- `longhorn-general-storageclass.yaml`
- `longhorn-general-multi-attach-storageclass.yaml`
- base values from the service `helm-values/` directory
- optional `Secret/longhorn-values-override`

## Common Cluster-Specific Configuration

Clusters usually customize:

- default data path and disk scheduling policy
- replica count for volumes
- backup target and credentials
- ingress / gateway exposure for the Longhorn UI
- default storage class choice

## Override Values Pattern

Example `override.yaml`:

```yaml
defaultSettings:
  defaultReplicaCount: 2
  backupTarget: s3://longhorn-backups@us-east-1/
  createDefaultDiskLabeledNodes: true

ingress:
  enabled: true
  host: longhorn.example.com
```

## Operational Notes

- Longhorn works best when node disks are stable and not overly contended.
- Replica count should reflect the number of failure domains you actually have.
- Backups and snapshots are separate concerns; define both intentionally.

## Verification

```bash
kubectl get helmrelease -n longhorn-system longhorn
kubectl get pods -n longhorn-system
kubectl get sc | grep longhorn
```

Healthy signs:

- manager, driver, UI, and CSI components are `Running`
- expected Longhorn storage classes exist
- PVCs can bind and mount successfully

## Common Failure Modes

Volumes stay detached or degraded:
- verify node disk availability, replica scheduling, and network health

Backups fail:
- verify backup target URL and object storage credentials

PVCs do not bind:
- verify the intended storage class exists and is allowed by workload policies

## Related Docs

- [Longhorn Service Reference](../../reference/services/longhorn.md)
