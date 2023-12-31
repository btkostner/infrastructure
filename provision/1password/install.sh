#!/usr/bin/env bash

set -e

# This value is the 1password account ID. This can be found by running `op accounts list`.
OP_ACCOUNT="AVQ6FPWP5ZAUPN6GGDQUKDVXVE"
# This value is the 1password URL for the credential value.
OP_ITEM_CREDENTIAL="op://Infrastructure/1Password Connect/credential"
# This value is the 1password URL for the `1password-credentials.json` file.
OP_ITEM_FILE="op://Infrastructure/1Password Connect/uhbqchxx7lowhsqfbd7ssc7t64"

KUBE_CONTEXT="admin@btkostner"
KUBE_NAMESPACE="external-secrets"

echo "=== Pulling 1Password secrets"

op --account "$OP_ACCOUNT" read "$OP_ITEM_CREDENTIAL" > ./1password-token.secret
op --account "$OP_ACCOUNT" read "$OP_ITEM_FILE" > ./1password-credentials.json.secret

echo "=== Creating $KUBE_NAMESPACE namespace"

kubectl --context "$KUBE_CONTEXT" create namespace "$KUBE_NAMESPACE" --dry-run=client -o yaml | kubectl --context "$KUBE_CONTEXT" apply -f -

echo "=== Creating 1Password secret"

kubectl --context "$KUBE_CONTEXT" create secret -n "$KUBE_NAMESPACE" generic op-credentials \
    --from-file=token=./1password-token.secret \
    --from-file=1password-credentials.json=./1password-credentials.json.secret
