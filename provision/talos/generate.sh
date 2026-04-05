#!/usr/bin/env bash

set -e

if [ ! -f "talsecret.yaml" ]; then
  echo "=== Pulling secrets from 1Password"

  op read "op://Infrastructure/Talos Secrets/secrets.yaml" > talsecret.yaml
fi

echo "=== Generating configuration"

talhelper genconfig

# echo "=== Copying local talos configuration to primary storage"

# cp ./talosconfig ~/.talos/config
