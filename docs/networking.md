# Networking

This page covers networking for individual nodes, our private internal DNS and gateway, and our public DNS and gateways.

## Local Network

My Intel NUC cluster runs on a separate vlan powered by [Ubiquiti](https://www.ui.com).

| Kind                                    | Name                            | IP           |
| --------------------------------------- | ------------------------------- | ------------ |
| PiKVM                                   | PiKVM                           | 192.168.3.2  |
| SnapAV WB-800VPS-IPVM-18                | WattBox                         | 192.168.3.3  |
| Synology RS1221+                        | Behemoth                        | 192.168.3.4  |
| TESmart 4K UHD 16 Ports HDMI KVM Switch | KVM                             | 192.168.3.5  |
| Kubernetes control plane VIP            |                                 | 192.168.3.10 |
| Intel NUC11PAHI5                        | NUC 1                           | 192.168.3.11 |
| Intel NUC11PAHI5                        | NUC 2                           | 192.168.3.12 |
| Intel NUC11PAHI5                        | NUC 3                           | 192.168.3.13 |
| Intel NUC11PAHI5                        | NUC 4                           | 192.168.3.14 |
| Intel NUC11PAHI&                        | NUC 5                           | 192.168.3.15 |
| Kubernetes ingress VIP                  | cilium-ingress                  | 192.168.3.50 |
| Kubernetes ingress VIP                  | cilium-gateway-external-gateway | 192.168.3.51 |
| Kubernetes ingress VIP                  | cilium-gateway-internal-gateway | 192.168.3.52 |
| Blocky DNS                              | blocky-dns                      | 192.168.3.61 |

## Private Network

Private services live under `btkostner.network` and are reached with [Cloudflare Zero Trust](https://developers.cloudflare.com/cloudflare-one/). Devices run the Cloudflare One (WARP) client. A `cloudflared` deployment in the cluster (`cluster/networking/cloudflared`) connects the `cluster` tunnel to Cloudflare.

The tunnel has a private hostname route for `btkostner.network`, which also covers its subdomains. When a WARP client looks up a name such as `grafana.btkostner.network`, Cloudflare Gateway answers with a temporary IP in `172.64.128.0/20` and sends the traffic through the tunnel. The public zone is otherwise private, with `ha.btkostner.network` being the exception for Home Assistant webhooks.

`cloudflared` resolves the real address through [Blocky](https://0xerr0r.github.io/blocky/) (`192.168.3.61`). Blocky's `customDNS` mapping in `cluster/networking/blocky` answers `btkostner.network` and every subdomain with the `internal-gateway` IP (`192.168.3.52`). More specific entries override this for hosts that are not behind the gateway: `talos` (the Kubernetes API on the control plane nodes), `nuc-1` to `nuc-5`, `kvm`, and `behemoth`. Add an entry there when a new host needs to be reachable.

Gateway TCP and UDP proxying must stay enabled in Zero Trust for private hostname routing to work. The default device profile reconnects WARP 10 minutes after it is turned off (`auto_connect: 600`).

## Public Network

For public networking it's a pretty standard Kubernetes setup. One _abnormal_ thing about my setup is I use the new (and totally awesome) [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io). There is a single `external-gateway` resource that uses [MetalLB](https://metallb.universe.tf) to allocate the `192.68.3.50` IP address to it. Port forwarding with Ubiquiti allows my house public IP address to accept traffic and route to my cluster services.

To make this fully work, a DDNS job on the cluster keeps the `abraxis.tv` Cloudflare records and `ha.btkostner.network` pointed at my house public IP address. The remaining `btkostner.network` services are only reachable through Cloudflare Zero Trust.
