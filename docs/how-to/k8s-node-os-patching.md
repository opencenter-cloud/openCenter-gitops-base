# K8s Node OS Patching Process

This document explains how OS patching works on openCenter Kubernetes cluster nodes.

---

## How It Works

OS patching on cluster nodes is automated and engineer-controlled. The process uses Ansible
playbooks for scanning and patching, Prometheus for alerting, and Kured for safe reboots.

`unattended-upgrades` is disabled on all nodes — patching is always intentional.

### Scanning

A weekly cron job on the bastion runs an Ansible scan playbook against all nodes. The scan:

- Checks each node for pending security and non-security updates via `apt`
- Writes a Prometheus-compatible `.prom` file on each node
- The `.prom` file is picked up by node_exporter and scraped by Prometheus

If security updates are pending for more than 2 hours, a `NodeSecurityUpdatesPending` alert
fires and a support ticket is created automatically.

### Patching

When the alert fires (or during a scheduled maintenance window), an engineer runs the patch
playbook:

- Patches are applied one node at a time (`serial: 1`)
- By default only security updates are installed
- After patching, the `.prom` file is re-written with updated counts
- The alert auto-resolves once all pending patches are applied

Patching does NOT reboot the node — it only installs packages.

### Rebooting (if needed)

If a kernel update is applied, the OS writes `/var/run/reboot-required`. Kured (a DaemonSet
running on all nodes) handles this:

1. Detects the sentinel file
2. Acquires a cluster-wide lock (only one node reboots at a time)
3. Cordons the node (prevents new pods being scheduled)
4. Drains the node (evicts pods, respecting PodDisruptionBudgets)
5. Reboots the node
6. Uncordons the node after it comes back up

Reboots only happen within a configured maintenance window (time and days are cluster-specific).

---

## Patching Order

1. **Control plane nodes** — one at a time, verifying API server and etcd health after each
2. **Worker nodes** — one at a time in rolling fashion

---

## Key Components

| Component | Role |
|-----------|------|
| Ansible scan playbook | Identifies pending updates, writes metrics |
| Ansible patch playbook | Applies patches (security-only by default) |
| Cron (`/etc/cron.d/os-patch-scan`) | Schedules weekly scans from the bastion |
| Prometheus + node_exporter | Scrapes metrics, evaluates alert rules |
| Alertmanager + alert-proxy | Routes alerts, creates support tickets |
| Kured (DaemonSet in `kured-system`) | Handles safe node reboots within maintenance window |
| PodDisruptionBudgets | Protect workload availability during drain |

---

## Alert Summary

| Alert | Fires when | Auto-resolves when |
|-------|-----------|-------------------|
| `NodeSecurityUpdatesPending` | Security patches pending > 2h | Patches applied |
| `NodeTotalUpdatesPending` | Any updates pending > 30d | All updates applied |
| `NodeRebootPendingTooLong` | Reboot pending > 7d | Node is rebooted |
| `NodeOsScanStale` | Scan hasn't run in 10+ days | Successful scan runs |
