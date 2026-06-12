# Local Path Provisioner

Rancher Local Path Provisioner provides dynamic provisioning of persistent local storage using HostPath or Local volumes.

## Source

- **Upstream:** <https://github.com/rancher/local-path-provisioner>
- **Chart path:** `deploy/chart/local-path-provisioner` (no public Helm repo available)
- **Version:** 0.0.36

## Architecture

```text
GitRepository (pinned to tag v0.0.36)
  └── HelmRelease (chart path: deploy/chart/local-path-provisioner)
        └── valuesFrom:
              [0] base values (local-path-provisioner-values-base)
              [1] customer override (local-path-provisioner-values-override, optional)
```

## Key Configuration

| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `storageClass.name` | `local-path` | Name of the StorageClass created |
| `storageClass.defaultClass` | `false` | Whether to set as default StorageClass |
| `storageClass.reclaimPolicy` | `Delete` | PV reclaim policy |
| `storageClass.volumeBindingMode` | `WaitForFirstConsumer` | Binding mode |
| `nodePathMap[0].paths` | `/opt/local-path-provisioner` | Default host path for volumes |

## Upgrade

To upgrade, update the git tag in `source.yaml` and the values file reference in `kustomization.yaml`:

1. Update `source.yaml`: change `ref.tag` to the new version (e.g., `v0.0.37`)
2. Copy and rename the values file: `helm-values/values-0.0.37.yaml`
3. Update `kustomization.yaml`: change the `files` path to the new values file
4. Update `helmrelease.yaml` if the chart path changes (unlikely)

## Customer Overrides

Customers can override values by providing a secret named `local-path-provisioner-values-override` with key `override.yaml` in the `local-path-storage` namespace via their cluster pre-req kustomization.

## Reference Documentation

See [docs/reference/services/local-path-provisioner.md](../../../../docs/reference/services/local-path-provisioner.md) for the full service reference.
