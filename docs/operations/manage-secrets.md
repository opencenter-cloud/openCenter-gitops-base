---
id: manage-secrets
sidebar_label: Manage Secrets
description: Shows how to encrypt, store, and reconcile secrets with SOPS and age in openCenter.
doc_type: how-to
title: "Manage Secrets with SOPS"
audience: "platform engineers"
tags: [sops, age, secrets, gitops]
---

# Manage Secrets with SOPS

**Purpose:** For platform engineers, shows how to encrypt and decrypt secrets using SOPS with age encryption, covering key generation, configuration, and GitOps integration.

## Prerequisites

- SOPS installed (`sops --version`)
- age installed (`age --version`)
- Git access to repository
- kubectl access to cluster

This repository documents the workflow but does not provide a consumer `.sops.yaml`, age recipient, cluster key, provider credential, or secret value. Those are private, cluster-specific inputs. The example values below are placeholders only.

## Install Tools

### Install SOPS

```bash
# macOS
brew install sops

# Linux
curl -LO https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops
```

### Install age

```bash
# macOS
brew install age

# Linux
curl -LO https://github.com/FiloSottile/age/releases/download/v1.1.1/age-v1.1.1-linux-amd64.tar.gz
tar xzf age-v1.1.1-linux-amd64.tar.gz
sudo mv age/age /usr/local/bin/
sudo mv age/age-keygen /usr/local/bin/
```

## Steps

The examples below use a common cluster-repo layout where service overlays live under `applications/overlays/<cluster>/services/`. If your consumer repo uses a different root, keep the same intent and apply the examples to the equivalent paths in that repo.

### 1. Generate age keypair

```bash
# Create directory for keys
mkdir -p ~/.config/sops/age/

# Generate keypair for cluster
age-keygen -o ~/.config/sops/age/<cluster>_keys.txt
```

Output:
```
# public key: age1<generated-recipient>
AGE-SECRET-KEY-1<generated-private-key>
```

Save the public key (starts with `age1`).

### 2. Configure SOPS for repository

Create `.sops.yaml` in repository root:

```yaml
creation_rules:
  # Encrypt all YAML files in secrets/ directory
  - path_regex: secrets/.*\.yaml$
    age: age1<generated-recipient>
  
  # Encrypt override values with sensitive data
  - path_regex: .*/services/.*/helm-values/.*override.*\.ya?ml$
    encrypted_regex: ^(data|stringData|password|token|key|secret|cert|ca|tls)$
    age: age1<generated-recipient>
  
  # Encrypt all files in infrastructure/credentials/
  - path_regex: infrastructure/.*/credentials/.*
    age: age1<generated-recipient>
```

Commit `.sops.yaml`:

```bash
git add .sops.yaml
git commit -m "feat(security): configure SOPS encryption"
git push origin main
```

### 3. Create secret file

In the consumer repository, create the manifest beneath the path reconciled by the consumer-source Kustomization:
`applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml`.
The base repository does not contain this consumer file.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: cert-manager
type: Opaque
stringData:
  username: <database-user>
  password: <secret-value>
  connection-string: <consumer-specific-connection-string>
```

### 4. Encrypt secret

```bash
# Encrypt in place at the consumer-source path.
sops -e -i applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml
```

Encrypted file looks like:

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: database-credentials
    namespace: cert-manager
type: Opaque
stringData:
    username: ENC[AES256_GCM,data:abc123,iv:def456,tag:ghi789,type:str]
    password: ENC[AES256_GCM,data:jkl012,iv:mno345,tag:pqr678,type:str]
    connection-string: ENC[AES256_GCM,data:stu901,iv:vwx234,tag:yz567,type:str]
sops:
    kms: []
    gcp_kms: []
    azure_kv: []
    hc_vault: []
    age:
        - recipient: age1<generated-recipient>
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2024-02-14T10:35:00Z"
    mac: ENC[AES256_GCM,data:abc123,iv:def456,tag:ghi789,type:str]
    pgp: []
    encrypted_regex: ^(data|stringData)$
    version: 3.8.1
```

### 5. Add the encrypted manifest to the consumer Kustomization

In `applications/overlays/<cluster>/services/cert-manager/kustomization.yaml`, add the encrypted manifest as a resource:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: cert-manager
resources:
  - secrets/database-credentials.yaml
```

The Flux Kustomization in Step 8 reconciles this consumer path and supplies SOPS decryption. The checked-in base example contains no `cert-manager-override` file and no encrypted consumer Secret; create both in the consumer repository.

### 6. Commit encrypted secret

```bash
git add applications/overlays/<cluster>/services/cert-manager/kustomization.yaml
git add applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml
git commit -m "feat(secrets): add database credentials"
git push origin main
```

### 7. Create age key secret in cluster

```bash
# Create namespace if needed
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -

# Create secret with age private key
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/<cluster>_keys.txt \
  -n flux-system
```

Verify:

```bash
kubectl get secret sops-age -n flux-system
```

### 8. Configure the consumer-source Kustomization for decryption

Do not add consumer encrypted Secrets to the base-source install Kustomization. The checked-in base install is `cert-manager-base`, sourced from `opencenter-cert-manager`; consumer encrypted values require a second Kustomization sourced from the consumer's Flux `GitRepository` (`flux-system`). The checked-in example does not contain this consumer override file; create `applications/overlays/<cluster>/services/fluxcd/cert-manager-override.yaml` in the consumer repository:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager-override
  namespace: flux-system
spec:
  dependsOn:
    - name: sources
      namespace: flux-system
  interval: 15m
  retryInterval: 1m
  timeout: 10m
  path: applications/overlays/<cluster>/services/cert-manager
  targetNamespace: cert-manager
  prune: true
  wait: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  
  # Enable SOPS decryption
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

Register that Flux object from the consumer repository's activation Kustomization at `applications/overlays/<cluster>/services/fluxcd/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./cert-manager-override.yaml
```

### 9. Apply and verify

```bash
# Force reconciliation of the consumer source and its encrypted Secret.
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization cert-manager-override -n flux-system --with-source

# Check secret was decrypted and applied
kubectl get secret database-credentials -n cert-manager

# Verify decrypted values (base64 encoded)
kubectl get secret database-credentials -n cert-manager -o jsonpath='{.data.username}' | base64 -d
```

## Decrypt Locally

To view or edit encrypted secrets:

```bash
# View decrypted content
sops -d applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml

# Edit encrypted file (decrypts, opens editor, re-encrypts on save)
sops applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml

# Decrypt to file
sops -d applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml > /tmp/decrypted.yaml
```

## Rotate Age Keys

### 1. Generate new keypair

```bash
age-keygen -o ~/.config/sops/age/<cluster>_keys_new.txt
```

### 2. Add both recipients to `.sops.yaml`

Keep the old recipient while the files and cluster are being migrated. Replace the placeholders with the existing and newly generated public recipients.

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: >-
      age1<old-recipient>,
      age1<new-recipient>
```

Apply the same two-recipient rule to every relevant creation rule, including encrypted Helm overrides. Do not remove the old recipient yet.

### 3. Rewrap every encrypted file with `sops updatekeys`

```bash
# Rewrap every tracked SOPS file for both recipients. `sops filestatus`
# skips tracked plaintext files while covering secrets, credentials, and
# encrypted Helm overrides wherever they are stored.
while IFS= read -r -d '' file; do
  if sops filestatus "$file" >/dev/null 2>&1; then
    sops updatekeys -y "$file"
  fi
done < <(git ls-files -z)

# Test that the new private key can decrypt a representative file before
# changing the in-cluster key Secret.
SOPS_AGE_KEY_FILE=${HOME}/.config/sops/age/<cluster>_keys_new.txt \
  sops -d applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml >/dev/null
```

### 4. Commit, push, and reconcile while both keys are valid

```bash
# Stage the updated recipient rules and every tracked file that SOPS rewrote.
git add .sops.yaml
while IFS= read -r -d '' file; do
  if sops filestatus "$file" >/dev/null 2>&1; then
    git add -- "$file"
  fi
done < <(git ls-files -z)
git commit -m "chore(security): add rotated age recipient"
git push origin main

# Install both private keys without deleting the working key. The temporary
# file is private and is removed even if the pipeline fails or is interrupted.
COMBINED_KEY_FILE=$(mktemp "${TMPDIR:-/tmp}/sops-age-XXXXXX")
chmod 600 "$COMBINED_KEY_FILE"
cleanup() { rm -f "$COMBINED_KEY_FILE"; }
trap cleanup EXIT HUP INT TERM
cat ~/.config/sops/age/<cluster>_keys.txt \
    ~/.config/sops/age/<cluster>_keys_new.txt \
    > "$COMBINED_KEY_FILE"
kubectl create secret generic sops-age \
  --from-file=age.agekey="$COMBINED_KEY_FILE" \
  -n flux-system --dry-run=client -o yaml | kubectl apply -f -
```

Reconcile the consumer source Kustomization. In the checked-in cert-manager example, the base source is `opencenter-cert-manager` with install Kustomization `cert-manager-base`, while the consumer GitRepository is `flux-system` with override Kustomization `cert-manager-override`; use the corresponding actual names for another overlay.

```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization cert-manager-override -n flux-system --with-source
kubectl get kustomization cert-manager-override -n flux-system
kubectl get secret database-credentials -n cert-manager
```

Verify the Kustomization is `Ready=True` and decrypt a representative file with the new private key. Do not remove the old recipient or old private key until the pushed commit has reconciled successfully and this verification passes.

### 5. Remove the old recipient only after verification

Edit every applicable `.sops.yaml` creation rule to contain only `age1<new-recipient>`, then rewrap the files again:

```bash
while IFS= read -r -d '' file; do
  if sops filestatus "$file" >/dev/null 2>&1; then
    sops updatekeys -y "$file"
  fi
done < <(git ls-files -z)

git add .sops.yaml
while IFS= read -r -d '' file; do
  if sops filestatus "$file" >/dev/null 2>&1; then
    git add -- "$file"
  fi
done < <(git ls-files -z)
git commit -m "chore(security): retire old age recipient"
git push origin main
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization cert-manager-override -n flux-system --with-source
kubectl get kustomization cert-manager-override -n flux-system
SOPS_AGE_KEY_FILE=${HOME}/.config/sops/age/<cluster>_keys_new.txt \
  sops -d applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml >/dev/null
```

After this second reconciliation and verification, replace the cluster Secret with only the new private key. Use a mode-0600 temporary copy with trap cleanup, then retain the old private key in secure recovery storage until the retention policy permits destruction:

```bash
NEW_KEY_FILE=$(mktemp "${TMPDIR:-/tmp}/sops-age-new-XXXXXX")
chmod 600 "$NEW_KEY_FILE"
cleanup() { rm -f "$NEW_KEY_FILE"; }
trap cleanup EXIT HUP INT TERM
cp ~/.config/sops/age/<cluster>_keys_new.txt "$NEW_KEY_FILE"
kubectl create secret generic sops-age \
  --from-file=age.agekey="$NEW_KEY_FILE" \
  -n flux-system --dry-run=client -o yaml | kubectl apply -f -
flux reconcile kustomization cert-manager-override -n flux-system --with-source
kubectl get kustomization cert-manager-override -n flux-system
```

## Partial Encryption

Encrypt only specific fields using `encrypted_regex`:

`.sops.yaml`:

```yaml
creation_rules:
  - path_regex: .*/services/.*/helm-values/override-values\.ya?ml$
    encrypted_regex: ^(password|token|apiKey|secret|privateKey)$
    age: age1<generated-recipient>
```

File `override-values.yaml`:

```yaml
# Unencrypted
replicaCount: 3
logLevel: info

# Encrypted (matches regex)
database:
  password: <secret-value>  # Will be encrypted
  host: <database-host>  # Will NOT be encrypted
  
api:
  token: <secret-token>  # Will be encrypted
  endpoint: <api-endpoint>  # Will NOT be encrypted
```

After `sops -e -i override-values.yaml`:

```yaml
replicaCount: 3
logLevel: info
database:
    password: ENC[AES256_GCM,data:abc123,iv:def456,tag:ghi789,type:str]
    host: <database-host>
api:
    token: ENC[AES256_GCM,data:jkl012,iv:mno345,tag:pqr678,type:str]
    endpoint: <api-endpoint>
sops:
    # ... encryption metadata
```

## Troubleshooting

### "no age key found" error

Ensure age key is in correct location:

```bash
ls -la ~/.config/sops/age/
```

Set SOPS_AGE_KEY_FILE environment variable:

```bash
export SOPS_AGE_KEY_FILE=${HOME}/.config/sops/age/<cluster>_keys.txt
sops -d applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml
```

### FluxCD decryption fails

Check age secret exists:

```bash
kubectl get secret sops-age -n flux-system
```

Check Kustomization has decryption configured:

```bash
kubectl get kustomization my-service -n flux-system -o jsonpath='{.spec.decryption}'
```

View FluxCD logs:

```bash
flux logs --kind=Kustomization --name=my-service
```

### "MAC mismatch" error

File was modified after encryption. Re-encrypt:

```bash
sops -d applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml > /tmp/decrypted.yaml
sops -e /tmp/decrypted.yaml > applications/overlays/<cluster>/services/cert-manager/secrets/database-credentials.yaml
rm /tmp/decrypted.yaml
```

### Multiple age keys

To decrypt with multiple keys, add all public keys to `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: >-
      age1<recipient-one>,
      age1<recipient-two>
```

## Best Practices

1. **Never commit plaintext secrets** - Always encrypt before committing
2. **Backup age keys securely** - Store in password manager or vault
3. **Use separate keys per cluster** - Limit blast radius
4. **Rotate keys periodically** - Every 90 days recommended
5. **Use encrypted_regex for partial encryption** - Keep non-sensitive data readable
6. **Test decryption in CI/CD** - Catch encryption issues early
7. **Document key locations** - Team members need access for emergencies

## Alternative: Sealed Secrets

For comparison, Sealed Secrets is also available in openCenter-gitops-base. Use SOPS when:
- You need offline encryption/decryption
- You want key management outside cluster
- You need to encrypt non-Kubernetes files

Use Sealed Secrets when:
- You want controller-based decryption
- You prefer cluster-managed keys
- You only encrypt Kubernetes Secrets

## Next Steps

- Configure Helm values with encrypted secrets (see [configure-helm-values.md](configure-helm-values.md))
- Set up observability for secret rotation (see [setup-observability.md](setup-observability.md))
- Implement secret rotation automation
