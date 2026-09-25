# Kube Prometheus Stack – Base Configuration

This directory contains the **base manifests** for deploying the [Kube Prometheus Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack), a comprehensive Kubernetes monitoring solution that bundles **Prometheus**, **Alertmanager**, **Grafana**, and related exporters.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../../docs/reference/services/kube-prometheus-stack.md).

**About Kube Prometheus Stack:**

- Provides a fully integrated monitoring stack for **Kubernetes clusters and workloads**.  
- Includes **Prometheus Operator** for managing Prometheus, Alertmanager, and related monitoring resources declaratively.  
- Deploys **Grafana** with preconfigured dashboards for nodes, pods, networking, and application metrics.  
- Automatically discovers targets and scrapes metrics using **ServiceMonitor** and **PodMonitor** CRDs.  
- Integrates with **Alertmanager** for alert routing, notification management, and on-call workflows.  
- Supports **custom alerting rules**, **recording rules**, and **Prometheus remote write** configurations.  
- Commonly used to gain real-time visibility into cluster performance, resource utilization, and application health.  

## Repository implementation

- Source path: `applications/base/services/observability/kube-prometheus-stack/`.
- Flux entrypoint: `kustomization.yaml`; the HelmRelease runs in `observability` and reads `kube-prometheus-stack-values-base` plus the optional `kube-prometheus-stack-values-override` Secret.
- Base values: `helm-values/values-91.4.1.yaml`; the base also includes the checked-in alertmanager, Prometheus, and alerting-rule override fragments.

## Validation and limitations

Run `kustomize build applications/base/services/observability/kube-prometheus-stack/` to validate the local manifests. The base does not guarantee scrape target discovery, notification credentials, or remote-write storage. Review selectors, retention, and alert routing in the cluster override before production use.
