#!/usr/bin/env sh
# [MISE] description="Build and validate Kubernetes manifests"

set -eu

validate() {
  dir=$1
  output=$(mktemp)
  trap 'rm -f "$output"' EXIT

  if [ ! -f "$dir/kustomization.yaml" ]; then
    rm -f "$output"
    return 0
  fi

  printf '=== Validating %s\n' "$dir"
  kustomize build --enable-helm "$dir" > "$output"
  kubeconform -strict -ignore-missing-schemas -summary < "$output"
  rm -f "$output"
}

for dir in \
  ./cluster/crds \
  ./cluster/*/*
do
  validate "$dir"
done
