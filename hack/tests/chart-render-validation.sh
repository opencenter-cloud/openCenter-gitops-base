#!/usr/bin/env bash
set -euo pipefail

# OCTR-796 validation intentionally exercises Helm charts locally. It does not
# require a Kubernetes cluster or Flux controllers.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/hack/tests/fixtures/octr-796"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/octr-796.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

assert_eq() {
  local actual=$1 expected=$2 description=$3
  [[ "$actual" == "$expected" ]] || fail "$description (expected '$expected', got '$actual')"
}

assert_yq_eq() {
  local file=$1 expression=$2 expected=$3 description=$4 actual
  actual="$(yq e -r "$expression" "$file")"
  assert_eq "$actual" "$expected" "$description"
}

assert_yq_contains() {
  local file=$1 expression=$2 expected=$3 description=$4 output
  output="$(yq ea -r "$expression" "$file")"
  if ! grep -Fq -- "$expected" <<<"$output"; then
    fail "$description (missing '$expected')"
  fi
}

assert_yq_nonempty() {
  local file=$1 expression=$2 description=$3 output
  output="$(yq ea -r "$expression" "$file" | grep -v '^---$' | sed '/^[[:space:]]*$/d')"
  [[ -n "$output" ]] || fail "$description (empty result)"
}

assert_output_contains() {
  local file=$1 expression=$2 expected=$3 description=$4 output
  output="$(yq ea -r "$expression" "$file")"
  if ! grep -Fq -- "$expected" <<<"$output"; then
    fail "$description (missing '$expected')"
  fi
}

assert_no_configmap_string() {
  local file=$1 sentinel=$2 description=$3 output
  output="$(yq ea -r 'select(.kind == "ConfigMap") | .. | select(tag == "!!str")' "$file")"
  if grep -Fq -- "$sentinel" <<<"$output"; then
    fail "$description (found '$sentinel' in a ConfigMap)"
  fi
}

fetch_chart() {
  local repo=$1 chart=$2 version=$3 destination=$4 chart_version
  helm pull --repo "$repo" "$chart" --version "$version" --untar --untardir "$destination"
  chart_version="$(yq e -r '.version' "$destination/$chart/Chart.yaml")"
  assert_eq "$chart_version" "$version" "$chart chart version"
}

check_values_from() {
  local file=$1 expected_names=$2 expected_length=$3
  assert_yq_eq "$file" '.spec.valuesFrom | length' "$expected_length" "$file valuesFrom length"
  assert_yq_eq "$file" '.spec.valuesFrom | map(.name) | join(",")' "$expected_names" "$file valuesFrom order"

  assert_yq_eq "$file" '.spec.valuesFrom[0] | keys | sort | join(",")' \
    'kind,name,valuesKey' "$file base valuesFrom shape"
  assert_yq_eq "$file" '.spec.valuesFrom[0].kind' Secret "$file base valuesFrom kind"
  assert_yq_eq "$file" '.spec.valuesFrom[0].valuesKey' values.yaml "$file base valuesFrom key"
  assert_yq_eq "$file" '.spec.valuesFrom[0].optional // "false"' false "$file base valuesFrom optional"

  assert_yq_eq "$file" '.spec.valuesFrom[1] | keys | sort | join(",")' \
    'kind,name,optional,valuesKey' "$file override valuesFrom shape"
  assert_yq_eq "$file" '.spec.valuesFrom[1].kind' Secret "$file override valuesFrom kind"
  assert_yq_eq "$file" '.spec.valuesFrom[1].valuesKey' override.yaml "$file override valuesFrom key"
  assert_yq_eq "$file" '.spec.valuesFrom[1].optional' true "$file override valuesFrom optional"

  if [[ "$expected_length" == 3 ]]; then
    assert_yq_eq "$file" '.spec.valuesFrom[2] | keys | sort | join(",")' \
      'kind,name,optional,valuesKey' "$file final valuesFrom shape"
    assert_yq_eq "$file" '.spec.valuesFrom[2].kind' Secret "$file final valuesFrom kind"
    assert_yq_eq "$file" '.spec.valuesFrom[2].valuesKey' values.yaml "$file final valuesFrom key"
    assert_yq_eq "$file" '.spec.valuesFrom[2].optional' true "$file final valuesFrom optional"
  fi
}

require_command helm
require_command yq

CHARTS_DIR="$TMP_DIR/charts"
mkdir -p "$CHARTS_DIR"
fetch_chart https://helm.goharbor.io harbor 1.19.2 "$CHARTS_DIR"
fetch_chart https://grafana.github.io/helm-charts loki 7.3.0 "$CHARTS_DIR"
fetch_chart https://grafana.github.io/helm-charts mimir-distributed 6.2.0 "$CHARTS_DIR"

check_values_from "$ROOT_DIR/applications/base/services/harbor/helmrelease.yaml" \
  harbor-values-base,harbor-values-override,opencenter-harbor-secret 3
check_values_from "$ROOT_DIR/applications/base/services/observability/loki/helmrelease.yaml" \
  loki-values-base,loki-values-override,opencenter-loki-secret 3
check_values_from "$ROOT_DIR/applications/base/services/observability/mimir/helmrelease.yaml" \
  mimir-values-base,mimir-values-override 2
assert_yq_eq "$ROOT_DIR/applications/base/services/harbor/helmrelease.yaml" \
  '.spec.chart.spec.chart' harbor 'Harbor Helm chart name'
assert_yq_eq "$ROOT_DIR/applications/base/services/harbor/helmrelease.yaml" \
  '.spec.chart.spec.version' 1.19.2 'Harbor Helm chart version'
assert_yq_eq "$ROOT_DIR/applications/base/services/observability/loki/helmrelease.yaml" \
  '.spec.chart.spec.chart' loki 'Loki Helm chart name'
assert_yq_eq "$ROOT_DIR/applications/base/services/observability/loki/helmrelease.yaml" \
  '.spec.chart.spec.version' 7.3.0 'Loki Helm chart version'
assert_yq_eq "$ROOT_DIR/applications/base/services/observability/mimir/helmrelease.yaml" \
  '.spec.chart.spec.chart' mimir-distributed 'Mimir Helm chart name'
assert_yq_eq "$ROOT_DIR/applications/base/services/observability/mimir/helmrelease.yaml" \
  '.spec.chart.spec.version' 6.2.0 'Mimir Helm chart version'

render() {
  local release=$1 chart=$2 values=$3 output=$4
  shift 4
  helm template "$release" "$CHARTS_DIR/$chart" \
    -f "$ROOT_DIR/applications/base/services/$values" "$@" >"$output"
}

HARBOR_BASE="harbor/helm-values/values-1.19.2.yaml"
LOKI_BASE="observability/loki/helm-values/values-7.3.0.yaml"
MIMIR_BASE="observability/mimir/helm-values/values-6.2.0.yaml"

render harbor harbor "$HARBOR_BASE" "$TMP_DIR/harbor-filesystem.yaml"
assert_yq_contains "$TMP_DIR/harbor-filesystem.yaml" \
  'select(.kind == "ConfigMap" and .metadata.name == "harbor-core") | .data.REGISTRY_STORAGE_PROVIDER_NAME' \
  filesystem 'Harbor filesystem provider'
for sentinel in Harbor12345 harbor_registry_password changeit not-a-secure-key; do
  assert_no_configmap_string "$TMP_DIR/harbor-filesystem.yaml" "$sentinel" \
    'Harbor filesystem credential sentinel check'
done

render harbor harbor "$HARBOR_BASE" "$TMP_DIR/harbor-s3.yaml" \
  -f "$FIXTURE_DIR/harbor-s3.yaml"
assert_yq_contains "$TMP_DIR/harbor-s3.yaml" \
  'select(.kind == "ConfigMap" and .metadata.name == "harbor-core") | .data.REGISTRY_STORAGE_PROVIDER_NAME' \
  s3 'Harbor S3 provider'
assert_output_contains "$TMP_DIR/harbor-s3.yaml" \
  'select(.kind == "ConfigMap" and .metadata.name == "harbor-registry") | .data["config.yml"]' \
  'bucket: octr796-harbor' 'Harbor S3 bucket'
assert_no_configmap_string "$TMP_DIR/harbor-s3.yaml" OCTR796-HARBOR-PASSWORD \
  'Harbor S3 credential sentinel check'

for storage in none s3 swift; do
  render loki loki "$LOKI_BASE" "$TMP_DIR/loki-$storage.yaml" \
    -f "$FIXTURE_DIR/loki-$storage.yaml"
  assert_yq_nonempty "$TMP_DIR/loki-$storage.yaml" \
    'select(.kind == "Secret" and .metadata.name == "loki") | .data["config.yaml"]' \
    "Loki $storage config Secret"
done

assert_output_contains "$TMP_DIR/loki-none.yaml" \
  'select(.kind == "Secret" and .metadata.name == "loki") | .data["config.yaml"] | @base64d' \
  'object_store: filesystem' 'Loki filesystem config'
assert_output_contains "$TMP_DIR/loki-s3.yaml" \
  'select(.kind == "Secret" and .metadata.name == "loki") | .data["config.yaml"] | @base64d' \
  'object_store: s3' 'Loki S3 config'
assert_output_contains "$TMP_DIR/loki-swift.yaml" \
  'select(.kind == "Secret" and .metadata.name == "loki") | .data["config.yaml"] | @base64d' \
  'object_store: swift' 'Loki Swift config'
for sentinel in OCTR796-ACCESS OCTR796-SECRET OCTR796-USER OCTR796-PASS; do
  for storage in none s3 swift; do
    assert_no_configmap_string "$TMP_DIR/loki-$storage.yaml" "$sentinel" \
      'Loki credential sentinel check'
  done
done

render mimir mimir-distributed "$MIMIR_BASE" "$TMP_DIR/mimir-secret-env.yaml" \
  -f "$FIXTURE_DIR/mimir-secret-env.yaml"
assert_yq_contains "$TMP_DIR/mimir-secret-env.yaml" \
  'select(.kind == "Deployment" or .kind == "StatefulSet") | .spec.template.spec.containers[]?.env[]? | select(.name == "AWS_ACCESS_KEY_ID") | .valueFrom.secretKeyRef.name' \
  mimir-object-store 'Mimir access key Secret reference'
assert_yq_contains "$TMP_DIR/mimir-secret-env.yaml" \
  'select(.kind == "Deployment" or .kind == "StatefulSet") | .spec.template.spec.containers[]?.env[]? | select(.name == "AWS_SECRET_ACCESS_KEY") | .valueFrom.secretKeyRef.name' \
  mimir-object-store 'Mimir secret key Secret reference'
assert_output_contains "$TMP_DIR/mimir-secret-env.yaml" \
  'select(.kind == "ConfigMap" and .metadata.name == "mimir-config") | .data["mimir.yaml"]' \
  'access_key_id: ${AWS_ACCESS_KEY_ID}' 'Mimir config env expansion'
assert_output_contains "$TMP_DIR/mimir-secret-env.yaml" \
  'select(.kind == "ConfigMap" and .metadata.name == "mimir-config") | .data["mimir.yaml"]' \
  'secret_access_key: ${AWS_SECRET_ACCESS_KEY}' 'Mimir secret env expansion'

printf 'PASS: OCTR-796 chart-render validation\n'
