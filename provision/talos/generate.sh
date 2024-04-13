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

  # Use 1Password CLI to fill in secret values
  op --account AVQ6FPWP5ZAUPN6GGDQUKDVXVE inject -i controlplane.yaml -o controlplane.yaml
  op --account AVQ6FPWP5ZAUPN6GGDQUKDVXVE inject -i talosconfig -o talosconfig
  op --account AVQ6FPWP5ZAUPN6GGDQUKDVXVE inject -i worker.yaml -o worker.yaml

  # Update the talosconfig endpoint to the correct internal DNS name
  sed -i "" "s/127.0.0.1/talos.btkostner.network/" ./talosconfig
fi

echo "=== Copying local talos configuration to primary storage"

cp ./talosconfig ~/.talos/config
