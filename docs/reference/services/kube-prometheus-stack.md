---
id: service-kube-prometheus-stack
title: "kube-prometheus-stack"
sidebar_label: kube-prometheus-stack
description: Reference for the kube-prometheus-stack service in openCenter-gitops-base.
doc_type: reference
audience: "platform engineers, operators, SREs"
tags: [prometheus, grafana, alertmanager, observability]
---

# Kube Prometheus Stack

`kube-prometheus-stack` is the repository’s core metrics and alerting service. It packages Prometheus, Alertmanager, Grafana, and the Prometheus Operator into one deployment in the `observability` namespace.

## What This Repo Deploys

- `HelmRelease/kube-prometheus-stack`
- Base values Secret with:
  - `values.yaml`
  - `alertmanager-overrides.yaml`
  - `prometheus-overrides.yaml`
- Optional `kube-prometheus-stack-values-override`

## When to Use It

- You need baseline cluster monitoring and alerting.
- You want `ServiceMonitor`, `PodMonitor`, and `PrometheusRule` CRDs available to teams.
- You want Grafana and Alertmanager managed as part of the platform stack.

## Key Integration Points

- Grafana can integrate with Keycloak for SSO.
- Prometheus can remote-write to Mimir or another long-term backend.
- Alertmanager routing is usually cluster-specific.

## Example

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app
spec:
  selector:
    matchLabels:
      app: app
```

## Configuration Surfaces

- Service path: `applications/base/services/observability/kube-prometheus-stack/`
- Namespace: `observability`
- Flux object: `HelmRelease/kube-prometheus-stack`
- Base values Secret: `kube-prometheus-stack-values-base`
- Override values Secret: `kube-prometheus-stack-values-override`
- Source: Prometheus Community Helm repository

## Related Docs

- [kube-prometheus-stack Configuration Guide](../../how-to/services/kube-prometheus-stack.md)
- [Mimir Reference](mimir.md)

## Upstream References

- [kube-prometheus-stack chart docs](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)
- [Prometheus Operator docs](https://prometheus-operator.dev/docs/)
- [Prometheus configuration docs](https://prometheus.io/docs/)
