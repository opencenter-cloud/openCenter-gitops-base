---
id: drain-node-for-maintenance
title: "Drain a Node for Planned Maintenance"
sidebar_label: Drain Node
description: Safely drain a Kubernetes worker or control plane node for planned hardware maintenance or pre-scheduled maintenance windows.
doc_type: how-to
audience: "platform engineers, operators, SREs"
tags: [kubernetes, node-drain, maintenance, cordoning, workload-migration]
---

**Article ID:** KB00004  
**Last Modified:** 2025-06-24  
**Author:** Platform Engineering Team  
**Status:** Published  
**Category:** Kubernetes/Cluster Management/Maintenance  
**Tags:** `kubernetes`, `node-drain`, `maintenance`, `cordon`, `uncordon`, `pod-eviction`, `PDB`  
**Visibility:** Public

---

## Summary

How to safely drain a Kubernetes node to evacuate all workloads before performing planned hardware maintenance, firmware upgrades, OS patching, or any pre-scheduled maintenance activity.

---

## Prerequisites

- `kubectl` configured with admin credentials
- Sufficient capacity on remaining nodes to absorb evicted workloads
- Knowledge of any Pod Disruption Budgets (PDBs) that may block eviction
- Change management approval for production environments

---

## Procedure Overview

```text
1. Pre-checks → 2. Cordon → 3. Drain → 4. Perform Maintenance → 5. Uncordon → 6. Verify
```

---

## Solution

### Step 1: Pre-Maintenance Checks

```bash
# Confirm all nodes are Ready
kubectl get nodes -o wide

# Identify workloads on the target node
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=<node-name>

# Check Pod Disruption Budgets
kubectl get pdb --all-namespaces

# Verify remaining cluster capacity
kubectl top nodes
```

Pay attention to:

- StatefulSet pods (may need special handling)
- DaemonSet pods (will NOT be evicted by default)
- Pods with local storage (emptyDir/hostPath — see note below)
- Standalone pods without controllers (will be lost on drain)

> **⚠️ Important — Local Data (emptyDir / hostPath):**  
> Pods using `emptyDir` volumes store data locally on the node. This data is **permanently lost** when the pod is evicted — it does not follow the pod to its new node. Common uses include caches, temp files, and sidecar communication. If this data matters, back it up before draining. The `--delete-emptydir-data` flag is required to evict these pods; without it, the drain will block.  
> Pods using `hostPath` volumes reference files directly on the node's filesystem. The data stays on the node, but the rescheduled pod will not have access to it on the new node. Ensure any critical `hostPath` data is replicated or no longer needed before proceeding.

Do not proceed if other nodes are already in a degraded state.

---

### Step 2: Cordon the Node

Marks the node as unschedulable — new pods won't land here, but existing pods keep running.

```bash
kubectl cordon <node-name>
```

Verify:

```bash
kubectl get node <node-name>
# Expected: Ready,SchedulingDisabled
```

---

### Step 3: Drain the Node

#### Standard Drain (Recommended for Production)

```bash
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=120 \
  --timeout=300s
```

| Flag | Purpose |
| ---- | ------- |
| `--ignore-daemonsets` | Skip DaemonSet-managed pods (they run on every node) |
| `--delete-emptydir-data` | Allow eviction of pods using emptyDir volumes |
| `--grace-period=120` | Give pods 120 seconds for graceful shutdown |
| `--timeout=300s` | Abort drain if not completed within 5 minutes |

#### Force Drain (Use with Caution)

Only use when standalone pods (no controller) exist and you accept losing them:

```bash
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --grace-period=60 \
  --timeout=300s
```

⚠️ **Warning:** `--force` deletes standalone pods permanently. They will NOT be rescheduled.

#### Verify Drain Completed

```bash
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=<node-name>
```

Only DaemonSet-managed pods (e.g., `kube-proxy`, `CNI pods`, `node-exporter`) should remain.

---

### Step 4: Perform Maintenance

With the node drained, safely perform your maintenance:

- Power off for hardware work
- Reboot for kernel/firmware updates
- Perform storage or network changes

---

### Step 5: Uncordon the Node (Post-Maintenance)

Wait for the node to report `Ready` (kubelet restart may take 1-2 minutes after reboot):

```bash
kubectl get node <node-name> -w
```

Then re-enable scheduling:

```bash
kubectl uncordon <node-name>
```

---

### Step 6: Post-Maintenance Verification

```bash
# Node should show Ready (no SchedulingDisabled)
kubectl get node <node-name>

# Check node conditions
kubectl describe node <node-name> | grep -A 10 "Conditions:"

# Verify DaemonSet pods are running
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=<node-name>

# Check resource utilization
kubectl top node <node-name>
```

---

## Draining a Control Plane Node

Additional precautions:

- **Never drain more than one control plane node at a time**
- **Verify etcd quorum** before and after the drain

```bash
# 1. Verify etcd health first
kubectl exec -n kube-system etcd-<another-cp-node> -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  endpoint health --cluster

# 2. Cordon + Drain (static pods won't be evicted)
kubectl cordon <cp-node-name>
kubectl drain <cp-node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=120 \
  --timeout=300s

# 3. Perform maintenance

# 4. Uncordon and verify etcd health
kubectl uncordon <cp-node-name>
kubectl exec -n kube-system etcd-<cp-node-name> -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  endpoint health --cluster
```

---

## Troubleshooting

### Drain Blocked by PDB

```text
Cannot evict pod as it would violate the pod's disruption budget.
```

**Solutions:**

1. Wait for PDB to allow disruption (another replica may need to become ready)
2. Temporarily scale up the deployment: `kubectl scale deployment <name> -n <ns> --replicas=<current+1>`
3. As a last resort (with approval), temporarily delete the PDB

### Drain Hangs Indefinitely

A pod may have a very long `terminationGracePeriodSeconds`. Cancel (Ctrl+C) and retry with a shorter grace period:

```bash
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=30 \
  --timeout=120s
```

### Pods Not Rescheduling After Drain

Check for scheduling failures:

```bash
kubectl get events --field-selector reason=FailedScheduling --all-namespaces
kubectl describe pod <pod-name> -n <namespace>
```

Common causes: insufficient resources, node affinity rules, or taints/tolerations.

### Node Stuck in SchedulingDisabled After Uncordon

```bash
# Check for manual taints
kubectl describe node <node-name> | grep Taints

# Remove if present
kubectl taint nodes <node-name> key=value:NoSchedule-
```

---

## Best Practices

1. **Verify cluster capacity** before draining — ensure remaining nodes can absorb workloads
2. **Respect Pod Disruption Budgets** — they exist to protect service availability
3. **Drain one node at a time** in production
4. **Use appropriate grace periods** — give pods time for graceful shutdown
5. **Monitor during drain** — `kubectl get events --watch --all-namespaces`
6. **Test in non-production first** when possible

---

## Quick Reference

| Action | Command |
| ------ | ------- |
| Cordon node | `kubectl cordon <node-name>` |
| Drain node | `kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --grace-period=120 --timeout=300s` |
| Check drain progress | `kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=<node-name>` |
| Uncordon node | `kubectl uncordon <node-name>` |
| Force drain | `kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --force` |

---

## Revision History

| Date | Version | Author | Change Description |
| ---- | ------- | ------ | ------------------ |
| 2025-06-24 | 1.0 | Platform Engineering Team | Initial creation |

---

## Related Articles

- [Replace a Failed Control Plane Node](replace-control-plane-node.md)
- [Version Upgrade Guide](version-upgrade-guide.md)
- [Troubleshoot Flux](troubleshoot-flux.md)
