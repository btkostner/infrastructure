#!/usr/bin/env bash

set -e

if [ ! -f "./talosconfig" ]; then
  echo "=== Generating configuration"

  patch_args=""
  for patch in ./patches/*.yaml; do
    echo "Detecting patch file $patch"
    patch_args+=" --config-patch @$patch"
  done

  talosctl gen config btkostner https://talos.btkostner.network:6443 \
    $patch_args \
    --endpoints talos.btkostner.network \
    --force

  # Update the talosconfig endpoint to the correct internal DNS name
  sed -i "" "s/127.0.0.1/talos.btkostner.network/" ./talosconfig
fi

echo "=== Copying local talos configuration to primary storage"

cp ./talosconfig ~/.talos/config
