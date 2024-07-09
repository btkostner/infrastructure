#!/usr/bin/env bash

set -e

if [ ! -f "secrets.yaml" ]; then
  echo "=== Pulling secrets from 1Password"

  op read "op://Infrastructure/Talos Secrets/secrets.yaml" > secrets.yaml
fi

if [ ! -f "./talosconfig" ]; then
  echo "=== Generating configuration"

  patch_args=""
  for patch in ./patches/*.yaml; do
    echo "Detecting patch file $patch"
    patch_args+=" --config-patch @$patch"
  done

  talosctl gen config btkostner https://talos.btkostner.network:6443 \
    $patch_args \
    --additional-sans 127.0.0.1 \
    --additional-sans 192.168.3.10 \
    --additional-sans 192.168.3.11 \
    --additional-sans 192.168.3.12 \
    --additional-sans 192.168.3.13 \
    --additional-sans 192.168.3.14 \
    --additional-sans 192.168.3.15 \
    --additional-sans 192.168.3.16 \
    --additional-sans 192.168.3.17 \
    --additional-sans 192.168.3.18 \
    --endpoints talos.btkostner.network \
    --force \
    --with-secrets secrets.yaml
fi

echo "=== Copying local talos configuration to primary storage"

cp ./talosconfig ~/.talos/config
