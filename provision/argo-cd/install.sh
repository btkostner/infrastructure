#!/usr/bin/env bash

set -e

KUBE_CONTEXT="admin@btkostner"
KUBE_NAMESPACE="argocd"

echo "=== Creating argocd namespace"

kubectl --context "$KUBE_CONTEXT" create namespace "$KUBE_NAMESPACE" --dry-run=client -o yaml | kubectl --context "$KUBE_CONTEXT" apply -f -

echo "=== Installing Argo CD"

cd "$(dirname "$0")/../../cluster/core/argocd/argo-cd"
kubectl --context "$KUBE_CONTEXT" kustomize . | kubectl --context "$KUBE_CONTEXT" apply -n "$KUBE_NAMESPACE" -f -
