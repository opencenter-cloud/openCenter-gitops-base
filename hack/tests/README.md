# Chart-render validation

`chart-render-validation.sh` is the durable, networked validation for OCTR-796.
It downloads and version-checks the pinned Harbor 1.19.2, Loki 7.3.0, and
Mimir 6.2.0 charts, then renders checked-in fixtures with Helm.

## Run

Requirements: Helm and [mikefarah/yq](https://github.com/mikefarah/yq).

```bash
bash hack/tests/chart-render-validation.sh
```

The test checks HelmRelease `valuesFrom` order, Secret kind, values keys, and
optional flags; Harbor filesystem/S3 storage; Loki filesystem/S3/Swift storage;
credential sentinels staying out of ConfigMaps; Loki configuration being
stored in a Secret; and Mimir `secretKeyRef` environment injection plus config
environment expansion.

The test deliberately does **not** claim to validate Flux behavior. Missing
external Secret failure behavior, Helm-controller values merge semantics,
reconciliation, and rollout/readiness require a live Flux/Kubernetes
environment and are outside this test's assertions.

The fixtures use non-routable example endpoints and sentinel credentials. They
are render-only values; no external object store or Kubernetes Secret is
created.
