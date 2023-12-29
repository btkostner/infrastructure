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
