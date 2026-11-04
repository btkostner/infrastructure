<h1 align="center">
  Infrastructure
</h1>

<p align="center">
  <img height="200" src="./docs/images/talos.svg" alt="Talos">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img height="200" src="./docs/images/kubernetes.svg" alt="Kubernetes">
</p>

This repository includes all of the configuration and documentation for my home lab cluster.

This cluster consists of 4 Intel Nucs running [Talos Linux](https://www.talos.dev) with a Synology NAS for large data. More information about this repository and cluster is available at <https://infrastructure.btkostner.io>.

## Features

- [Talos Linux](https://www.talos.dev) cluster with NVMe as a boot drive and SSD for data
- [Argo CD autopilot](https://argocd-autopilot.readthedocs.io/en/stable/) for cluster bootstrapping
- [Cilium](https://cilium.io) as a kube proxy replacement and sidecar-less networking
- [Rook Ceph](https://rook.io) for stateful replicated storage for all nodes
- [Velero](https://velero.io) for offsite cluster backup

## Media services

- [Dispatcharr](https://dispatcharr.github.io/Dispatcharr-Docs/) runs in the `media` namespace at <https://dispatcharr.btkostner.network> through the internal gateway. Its all-in-one container stores application data, PostgreSQL, and recordings on a 10Gi `ceph-safe-block` volume mounted at `/data`. External traffic and DNS from the pod are routed through Mullvad WireGuard by a Gluetun native sidecar with its firewall kill switch enabled; Dispatcharr starts only after Gluetun is healthy. HTTP ingress on port `9191` and in-cluster pod/service traffic (`10.244.0.0/16`, `10.96.0.0/12`) are allowed outside the tunnel. To refresh the `gluetun-credentials` item in 1Password, generate a Mullvad WireGuard configuration for an active account and device, then copy `Interface.PrivateKey` into `private-key` and `Interface.Address` into `addresses` in that same configuration. If `Interface.Address` contains multiple CIDR values, enter them comma-separated. The `dispatcharr-vpn` ExternalSecret maps these fields to Gluetun's `WIREGUARD_PRIVATE_KEY` and `WIREGUARD_ADDRESSES` environment variables. Create the first admin account in the web interface, then add M3U and EPG sources. In-cluster clients can use `http://dispatcharr.media.svc.cluster.local`. Argo CD discovers `cluster/media/dispatcharr/kustomization.yaml` after it is pushed to `main`.
