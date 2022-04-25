#!/bin/sh
# This will use talosctl to generate a new talos configuration

talosctl gen config btkostner https://192.168.1.150:6443 \
  --additional-sans 192.168.1.151,192.168.1.152,192.168.1.153,192.168.1.150,192.168.0.1 \
  --config-patch-control-plane "@controlplane.patch.json" \
  --config-patch-worker "@worker.patch.json" \
  --persist=false \
  --with-cluster-discovery=false \
  --with-docs=false \
  --with-examples=false
