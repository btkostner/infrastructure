# Networking

This page covers networking for individual nodes, our private internal DNS and gateway, and our public DNS and gateways.

## Local Network

My Intel NUC cluster runs on a separate vlan powered by [Ubiquiti](https://www.ui.com).

| Kind                         | Name                            | IP           |
| ---------------------------- | ------------------------------- | ------------ |
| PiKVM                        | kvm                             | 192.168.3.2  |
| SnapAV WB-800VPS-IPVM-18     | WattBox                         | 192.168.3.3  |
| Synology RS1221+             | Behemoth                        | 192.168.3.4  |
| Kubernetes control plane VIP |                                 | 192.168.3.10 |
| Intel NUC11PAHI5             | NUC 1                           | 192.168.3.11 |
| Intel NUC11PAHI5             | NUC 2                           | 192.168.3.12 |
| Intel NUC11PAHI5             | NUC 3                           | 192.168.3.13 |
| Intel NUC11PAHI5             | NUC 4                           | 192.168.3.14 |
| Kubernetes ingress VIP       | cilium-ingress                  | 192.168.3.50 |
| Kubernetes ingress VIP       | cilium-gateway-external-gateway | 192.168.3.51 |

## Private Network

To make things easier, I have a [Tailscale](https://tailscale.com) network for everything. This makes it easy for all of my devices to access private services on the cluster. To make it _even_ easier, I have a full DNS setup with Cloudflare at `btkostner.network`. All IPs in that zone point to _private_ local network IPs or Tailscale IPs.

Currently the PiKVM and Synology NAS has built in Tailscale support, so they _just work™_. This allows me to access my kvm from any device with Tailscale setup by opening a browser and accessing <https://kvm.btkostner.network>, similarly my nas with <https://behemoth.btkostner.network>.

For the Kubernetes cluster.... TODO....

## Public Network

For public networking it's a pretty standard Kubernetes setup. One _abnormal_ thing about my setup is I use the new (and totally awesome) [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io). There is a single `external-gateway` resource that uses [MetalLB](https://metallb.universe.tf) to allocate the `192.68.3.50` IP address to it. Port forwarding with Ubiquiti allows my house public IP address to accept traffic and route to my cluster services.

To make this fully work, I also have some ddns jobs on the cluster that set the required Cloudflare records pointing to my house public IP address.
