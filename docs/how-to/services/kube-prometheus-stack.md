---
id: kube-prometheus-stack-config-guide
title: "Kube-Prometheus-Stack Configuration Guide"
sidebar_label: Prometheus Stack
description: How to configure kube-prometheus-stack in cluster repositories that consume the openCenter base.
doc_type: how-to
audience: "platform engineers, operators"
tags: [prometheus, grafana, monitoring, observability, kubernetes]
---

# Kube-Prometheus-Stack Configuration Guide

Use this guide when a cluster repo needs to tune the monitoring stack deployed from `applications/base/services/observability/kube-prometheus-stack/`.

## What the Base Deploys

The base service deploys:

- `HelmRelease/kube-prometheus-stack`
- a single base Secret containing:
  - `values.yaml`
  - `alertmanager-overrides.yaml`
  - `prometheus-overrides.yaml`
- an optional `kube-prometheus-stack-values-override` Secret

This means cluster repos normally supply only the delta in `override.yaml`.

## Common Cluster-Specific Configuration

Most clusters customize:

- Grafana ingress / gateway hostname and SSO
- Prometheus retention and storage size
- Alertmanager routes, receivers, and secret references
- `ServiceMonitor` and `PodMonitor` resources for cluster-local services
- remote-write settings to Mimir or another backend

## Override Values Pattern

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: observability

secretGenerator:
  - name: kube-prometheus-stack-values-override
    files:
      - override.yaml=override.yaml
    options:
      disableNameSuffixHash: true
```

Example `override.yaml`:

```yaml
grafana:
  ingress:
    enabled: true
    hosts:
      - grafana.example.com

prometheus:
  prometheusSpec:
    retention: 15d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: longhorn-general
          resources:
            requests:
              storage: 100Gi
```

## Operational Considerations

- Keep an eye on Prometheus cardinality and retention because they dominate memory and disk growth.
- Treat Alertmanager routes and receiver credentials as cluster-local inputs.
- Decide early whether Grafana is authoritative for dashboards or whether dashboards are provisioned from Git.

## Verification

```bash
kubectl get helmrelease -n observability kube-prometheus-stack
kubectl get pods -n observability
kubectl get servicemonitors,podmonitors,prometheusrules -A
kubectl get prometheus,alertmanager -n observability
```

Healthy signs:

- operator, Prometheus, Grafana, and Alertmanager Pods are `Running`
- `HelmRelease/kube-prometheus-stack` is `Ready=True`
- Prometheus targets are scraping expected services

## Common Failure Modes

Prometheus OOM or disk pressure:
- reduce retention, fix high-cardinality metrics, or increase resources

Grafana login problems:
- verify OIDC redirect URIs, secrets, and root URL

Alerts do not send:
- verify Alertmanager config Secret contents and receiver connectivity

Expected metrics missing:
- check label selectors and namespaces on `ServiceMonitor` / `PodMonitor`

## Related Docs

- [kube-prometheus-stack Service Reference](../../reference/services/kube-prometheus-stack.md)
