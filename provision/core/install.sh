#!/usr/bin/env bash

set -e

KUBE_CONTEXT="admin@btkostner"

echo "=== Installing CRDs"

kubectl kustomize "$(dirname "$0")/../../cluster/crds/" --enable-helm | kubectl --context "$KUBE_CONTEXT" apply -f -

echo "=== Installing Core Resources"

kubectl kustomize "$(dirname "$0")/../../cluster/core/" --enable-helm | kubectl --context "$KUBE_CONTEXT" apply -f -
