# GitOps Service Deployment Guide

## Deploying and Managing Services on OpenCenter Kubernetes Clusters

**Document Version:** 1.0  
**Last Updated:** 2026-07-09  
**Audience:** OpenCenter Platform / Kubernetes Operations Team  
**Purpose:** This guide provides a complete end-to-end walkthrough for deploying and managing services on OpenCenter-managed Kubernetes clusters using FluxCD. It covers external infrastructure setup, GitOps configuration, secret encryption, and post-deployment validation using Velero with Rackspace Object Storage as a detailed example.

> **Reading order:** Start with [Helm Service Onboarding](helm-service-onboarding.md) to understand the generic onboarding pattern (directory layout, sources, Kustomizations, overrides). Then use this guide as a hands-on walkthrough that applies the same pattern to a real service deployment including the infrastructure steps that sit outside Git.

---

## GitOps Workflow for Service Changes

The same workflow applies to any service managed through FluxCD on OpenCenter clusters. Whether you are deploying a new service, updating helm values, changing a configuration, or adding a new cluster overlay, the process is:

1. Create a feature branch
2. Make your changes in the appropriate cluster overlay directory (`applications/overlays/<cluster-name>/services/`)
3. Encrypt any secrets with SOPS
4. Commit, push, and raise a PR
5. Once merged, FluxCD reconciles the changes automatically

The Velero deployment documented below is a practical example of this pattern. Use it as a reference when deploying or modifying other services (e.g., cert-manager, metallb, kube-prometheus-stack, etc.).

> **Note:** This example assumes vSphere CSI for Kubernetes storage. The concept remains the same for other CSI drivers, but the `VolumeSnapshotClass` driver value will differ (e.g., `csi.vsphere.vmware.com` for vSphere, `rbd.csi.ceph.com` for Ceph RBD).

---

## Prerequisites

- Access to the Rackspace Object Storage portal for your account
- AWS CLI installed locally ([installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- `sops` and `age` configured for secret encryption ([SOPS reference](https://github.com/opencenter-cloud/openCenter-gitops-base/blob/main/docs/reference/sops-configuration.md))
- Git access to the customer GitOps repository
- `kubectl` access to the target cluster (for validation)
- `velero` CLI installed ([Velero CLI docs](https://velero.io/docs/main/basic-install/#install-the-cli))

---

## Step 1: Create Rackspace Object Storage Secret Key

Create an access key and secret key from the Rackspace Object Storage portal. If a key already exists for your account, you can re-use it.

Refer: <https://docs.rackspace.com/docs/secret-key-creation>

Full documentation: <https://docs.rackspace.com/docs/rackspace-object-storage>

---

## Step 2: Configure AWS CLI

Configure the AWS CLI with the credentials obtained in Step 1:

```bash
aws configure
```

When prompted:

```text
AWS Access Key ID [None]: <your-access-key>
AWS Secret Access Key [None]: <your-secret-key>
Default region name [None]: us-east-1
Default output format [None]:
```

---

## Step 3: Create the S3 Bucket

Create a dedicated bucket for your cluster's Velero backups:

```bash
# List existing buckets (optional)
aws s3api list-buckets --endpoint-url https://<account-id>-<primary-id>.<region>.ros.rackspace.com

# Create the bucket
aws s3api create-bucket \
  --bucket <cluster-name>-velero-backups \
  --endpoint-url https://<account-id>-<primary-id>.<region>.ros.rackspace.com

# Verify bucket creation
aws s3api list-buckets --endpoint-url https://<account-id>-<primary-id>.<region>.ros.rackspace.com
```

Expected output:

```json
{
    "Buckets": [
        {
            "Name": "<cluster-name>-velero-backups",
            "CreationDate": "2026-01-01T00:00:00.000000+00:00"
        }
    ],
    "Owner": {
        "DisplayName": "...",
        "ID": "..."
    }
}
```

---

## Step 4: Create a Git Branch

All changes should go into a feature branch:

```bash
git checkout -b feature/velero-<cluster-name>
```

---

## Step 5: Create the GitOps Configuration Files

The following directory structure is needed under `applications/overlays/<cluster-name>/services/`:

```text
applications/overlays/<cluster-name>/services/
├── sources/
│   ├── kustomization.yaml        (update - add opencenter-velero.yaml)
│   └── opencenter-velero.yaml    (new)
├── fluxcd/
│   ├── kustomization.yaml        (update - add velero.yaml)
│   └── velero.yaml               (new)
└── velero/
    ├── pre-req/
    │   ├── kustomization.yaml
    │   ├── cloud-credentials-secret.yaml
    │   └── helm-values/
    │       └── override-values.yaml
    └── config/
        ├── kustomization.yaml
        └── schedule.yaml
```

### 5.1 — Source: `services/sources/opencenter-velero.yaml`

There are two source repository options depending on your deployment:

**Option A: Enterprise repo (private, requires `secretRef`)**

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: opencenter-velero
  namespace: flux-system
spec:
  interval: 15m
  url: https://github.com/opencenter-cloud/opencenter-gitops-enterprise.git
  ref:
    tag: "<enterprise-release-tag>"
  secretRef:
    name: opencenter-enterprise
```

**Option B: Community repo (public, no `secretRef` needed)**

If you are using the community base repo (`https://github.com/opencenter-cloud/openCenter-gitops-base.git`), it is a public repository and does not require a `secretRef`. You can reference either a specific tag or a branch:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: opencenter-velero
  namespace: flux-system
spec:
  interval: 15m
  url: https://github.com/opencenter-cloud/openCenter-gitops-base.git
  ref:
    # Use a tag for pinned releases:
    tag: "<community-release-tag>"
    # OR use a branch to track latest:
    # branch: main
```

> **Note:** When using the community repo, the `path` in the FluxCD Kustomization (section 5.7, `velero-base`) should point to the base velero install path in that repo instead of the enterprise overlay path.

Add it to `services/sources/kustomization.yaml`:

```yaml
resources:
  # ... existing sources ...
  - "opencenter-velero.yaml"
```

### 5.2 — Cloud Credentials: `services/velero/pre-req/cloud-credentials-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: velero-cloud-credentials
  namespace: velero
  labels:
    app.kubernetes.io/part-of: velero
    app.kubernetes.io/managed-by: flux
    opencenter/managed-by: opencenter
type: Opaque
stringData:
  cloud: |
    [default]
    aws_access_key_id=<your-access-key>
    aws_secret_access_key=<your-secret-key>
```

### 5.3 — Helm Values Override: `services/velero/pre-req/helm-values/override-values.yaml`

```yaml
---
credentials:
  extraSecretRef: "velero-cloud-credentials"

configuration:
  features: EnableCSI
  defaultSnapshotMoveData: false
  defaultVolumesToFsBackup: false
  backupStorageLocation:
    - name: default
      provider: aws
      bucket: <cluster-name>-velero-backups
      config:
        region: us-east-1
        s3Url: https://<account-id>-<primary-id>.<region>.ros.rackspace.com
        checksumAlgorithm: ""
        s3ForcePathStyle: "true"
      credential:
        key: cloud
        name: velero-cloud-credentials
  volumeSnapshotLocation: []

snapshotsEnabled: true
backupsEnabled: true
deployNodeAgent: false

initContainers:
  - name: velero-plugin-for-aws
    image: velero/velero-plugin-for-aws:v1.11.0
    imagePullPolicy: IfNotPresent
    volumeMounts:
      - mountPath: /target
        name: plugins

extraObjects:
  - apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshotClass
    metadata:
      name: velero-vsphere-snapshot-class
      labels:
        velero.io/csi-volumesnapshot-class: "true"
    driver: csi.vsphere.vmware.com
    deletionPolicy: Delete
```

### 5.4 — Pre-req Kustomization: `services/velero/pre-req/kustomization.yaml`

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: velero
resources:
  - cloud-credentials-secret.yaml
  - "../../global/rackspace-registry/"
secretGenerator:
  - name: velero-values-override
    type: Opaque
    files:
      - override.yaml=helm-values/override-values.yaml
    options:
      disableNameSuffixHash: true
```

> **Note:** The `../../global/rackspace-registry/` resource is only required when deploying from the enterprise repo. It provides credentials for pulling container images from the internal Rackspace registry. If you are using the community repo, all images are pulled from upstream public registries, so this line should be removed.

### 5.5 — Backup Schedule: `services/velero/config/schedule.yaml`

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: <cluster-name>
spec:
  schedule: "0 2 * * *"
  skipImmediately: false
  template:
    hooks: {}
    includedNamespaces:
      - cert-manager
      - vmware-system-csi
      - envoy-gateway-system
      - headlamp
      - keycloak
      - metallb-system
      - observability
      - olm
      - operators
      - postgres-operator
      - rackspace-system
      - rbac-system
      - velero
    snapshotVolumes: true
    storageLocation: default
    ttl: 72h
```

### 5.6 — Config Kustomization: `services/velero/config/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: velero
resources:
  - ./schedule.yaml
```

### 5.7 — FluxCD Kustomization: `services/fluxcd/velero.yaml`

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: velero-prereqs
  namespace: flux-system
spec:
  dependsOn:
    - name: sources
      namespace: flux-system
  interval: 15m
  retryInterval: 1m
  timeout: 5m
  decryption:
    provider: sops
    secretRef:
      name: sops-age
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  path: ./applications/overlays/<cluster-name>/services/velero/pre-req
  targetNamespace: velero
  prune: true
  wait: true
  commonMetadata:
    labels:
      app.kubernetes.io/part-of: velero
      app.kubernetes.io/managed-by: flux
      opencenter/managed-by: opencenter
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: velero-base
  namespace: flux-system
spec:
  dependsOn:
    - name: sources
      namespace: flux-system
  interval: 15m
  retryInterval: 1m
  timeout: 10m
  sourceRef:
    kind: GitRepository
    name: opencenter-velero
    namespace: flux-system
  # Enterprise repo path:
  path: ./applications/enterprise/services/velero/overlays/install
  # Community repo path:
  # path: ./applications/base/services/velero
  targetNamespace: velero
  prune: true
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2
      kind: HelmRelease
      name: velero
      namespace: velero
  commonMetadata:
    labels:
      app.kubernetes.io/part-of: velero
      app.kubernetes.io/managed-by: flux
      opencenter/managed-by: opencenter
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: velero-config
  namespace: flux-system
spec:
  dependsOn:
    - name: velero-base
      namespace: flux-system
  interval: 15m
  retryInterval: 1m
  timeout: 10m
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  path: ./applications/overlays/<cluster-name>/services/velero/config
  targetNamespace: velero
  prune: true
  commonMetadata:
    labels:
      app.kubernetes.io/part-of: velero
      app.kubernetes.io/managed-by: flux
      opencenter/managed-by: opencenter
```

Add it to `services/fluxcd/kustomization.yaml`:

```yaml
resources:
  # ... existing resources ...
  - ./velero.yaml
```

---

## Step 6: Encrypt the Cloud Credentials Secret

Before committing, encrypt the credentials file using SOPS:

```bash
sops -e -i applications/overlays/<cluster-name>/services/velero/pre-req/cloud-credentials-secret.yaml
```

Verify the file is encrypted (you should see `sops` metadata and encrypted values in the file).

---

## Step 7: Commit, Push, and Raise a PR

```bash
git add .
git commit -m "feat: deploy velero for <cluster-name> with Rackspace Object Storage"
git push -u origin feature/velero-<cluster-name>
```

Raise a Pull Request to merge into `main`. Once reviewed and merged, FluxCD will automatically reconcile and deploy Velero.

---

## Step 8: Verify Deployment

After merge, wait for FluxCD to reconcile (typically within 15 minutes), then verify:

```bash
# Check Flux Kustomizations
kubectl get kustomization -n flux-system | grep velero

# Check Velero pods
kubectl get pods -n velero

# Check BackupStorageLocation
kubectl get backupstoragelocation -n velero

# Check the schedule was created
kubectl get schedule -n velero
```

Expected: the `BackupStorageLocation` should show `Available` phase, and the schedule should exist.

---

## Step 9: Validate Backup and Restore (with PVC)

Create a test namespace with a pod and a PersistentVolumeClaim to validate both resource and volume backup/restore.

### 9.1 — Create test resources

```bash
# Create test namespace
kubectl create namespace velero-test

# Create a PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: velero-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Create a pod that writes data to the PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: velero-test
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["sh", "-c", "echo 'velero backup test data' > /data/testfile.txt && sleep 3600"]
      volumeMounts:
        - name: test-volume
          mountPath: /data
  volumes:
    - name: test-volume
      persistentVolumeClaim:
        claimName: test-pvc
EOF
```

Wait for the pod to be running:

```bash
kubectl wait --for=condition=Ready pod/test-pod -n velero-test --timeout=120s
```

### 9.2 — Take a backup

```bash
velero backup create test-backup \
  --include-namespaces velero-test \
  --snapshot-volumes \
  --wait
```

Check backup status:

```bash
velero backup describe test-backup
velero backup logs test-backup
```

### 9.3 — Simulate data loss

```bash
kubectl delete namespace velero-test
```

Verify it's gone:

```bash
kubectl get namespace velero-test
# Expected: Error from server (NotFound)
```

### 9.4 — Restore from backup

```bash
velero restore create test-restore \
  --from-backup test-backup \
  --wait
```

Check restore status:

```bash
velero restore describe test-restore
velero restore logs test-restore
```

### 9.5 — Verify restored resources

```bash
# Namespace should be back
kubectl get namespace velero-test

# Pod and PVC should be restored
kubectl get pods -n velero-test
kubectl get pvc -n velero-test

# Verify data on the PVC is intact
kubectl exec -n velero-test test-pod -- cat /data/testfile.txt
# Expected output: velero backup test data
```

### 9.6 — Cleanup test resources

```bash
velero backup delete test-backup --confirm
kubectl delete namespace velero-test
```

---

## Troubleshooting

| Symptom | Check |
| ------- | ----- |
| `BackupStorageLocation` shows `Unavailable` | Verify S3 credentials, endpoint URL, and bucket name. Check `velero-cloud-credentials` secret exists in `velero` namespace. |
| Backup completes but volumes are not snapshotted | Ensure the `VolumeSnapshotClass` has the label `velero.io/csi-volumesnapshot-class: "true"` and the CSI driver matches your storage provider. |
| FluxCD shows reconciliation error | Run `kubectl get kustomization -n flux-system velero-prereqs -o yaml` and check the status conditions. |
| SOPS decryption failure | Verify the `sops-age` secret exists in `flux-system` namespace and the `.sops.yaml` creation rules cover the path. |

---

## References

- [Helm Service Onboarding](helm-service-onboarding.md) — generic pattern guide for onboarding any Helm-based service via FluxCD
- [Rackspace Object Storage Documentation](https://docs.rackspace.com/docs/rackspace-object-storage)
- [Rackspace Secret Key Creation](https://docs.rackspace.com/docs/secret-key-creation)
- [AWS CLI Installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Velero Documentation](https://velero.io/docs/)
- [SOPS Configuration Reference](https://github.com/opencenter-cloud/openCenter-gitops-base/blob/main/docs/reference/sops-configuration.md)
