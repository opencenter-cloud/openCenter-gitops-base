# weave-gitops

Weave GitOps OSS dashboard — a web UI for visualising and managing Flux
resources (Kustomizations, HelmReleases, sources) in the cluster.

- Chart: `weave-gitops` (OCI `oci://ghcr.io/weaveworks/charts`), version `4.0.36`
- Namespace: `flux-system`
- Service: `ClusterIP` on port `9001`

The local admin user is enabled in the base values; its bcrypt password hash is
supplied per-cluster through the `weave-gitops-values-override` Secret rendered
by `opencenter cluster generate` from `secrets.weave_gitops.password`.
