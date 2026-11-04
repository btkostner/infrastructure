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

The tunnel has a private hostname route for `btkostner.network`, which also covers its subdomains. When a WARP client looks up a name such as `grafana.btkostner.network`, Cloudflare Gateway answers with a temporary IP in `172.64.128.0/20` and sends the traffic through the tunnel. The public `btkostner.network` zone has no A, AAAA, or CNAME records.

`cloudflared` resolves the real address through [Blocky](https://0xerr0r.github.io/blocky/) (`192.168.3.61`). Blocky's `customDNS` mapping in `cluster/networking/blocky` answers `btkostner.network` and every subdomain with the `internal-gateway` IP (`192.168.3.52`). More specific entries override this for hosts that are not behind the gateway: `talos` (the Kubernetes API on the control plane nodes), `nuc-1` to `nuc-5`, `kvm`, and `behemoth`. Add an entry there when a new host needs to be reachable.

Gateway TCP and UDP proxying must stay enabled in Zero Trust for private hostname routing to work. The default device profile reconnects WARP 10 minutes after it is turned off (`auto_connect: 600`).

Tautulli must have **HTTP Proxy** enabled (`http_proxy=1` in its persistent `/config/config.ini`) so redirects use HTTPS behind the gateway.

Talos must be able to start without Blocky or the Cloudflare tunnel. The shared configuration in `provision/talos/talconfig.yaml` uses Cloudflare's NTP IPs (`162.159.200.1` and `162.159.200.123`) and local host entries that map `talos.btkostner.network` to the three control-plane addresses (`192.168.3.11`–`192.168.3.13`). Keep these settings independent of cluster DNS. After a full power loss, start the network equipment, all three control-plane nodes, and both workers. Blocky must recover before `cloudflared` can resolve its destinations.

## Personal MCP portal

The shared endpoint is **`https://mcp.btkostner.io/mcp`**. [Cloudflare MCP server portals](https://developers.cloudflare.com/cloudflare-one/access-controls/ai-controls/mcp-portals/) combine the servers behind one authenticated endpoint. Clients do not need WARP. Private upstreams remain private.

| Server ID        | Upstream                                                         | Access                                                        |
| ---------------- | ---------------------------------------------------------------- | ------------------------------------------------------------- |
| `kubernetes`     | `https://kubernetes-mcp.btkostner.network/mcp`                   | Read-only; Secrets, External Secrets, and RBAC objects denied |
| `home-assistant` | `https://ha-mcp.btkostner.network` with the existing secret path | Existing Home Assistant permissions                           |
| `argocd`         | `https://argocd-mcp.btkostner.network/mcp`                       | Dedicated `argocd-mcp` account with `role:readonly`           |
| `cloudflare`     | `https://mcp.cloudflare.com/mcp`                                 | Permissions granted during upstream OAuth approval            |

The Kubernetes server is defined in `cluster/developer/kubernetes-mcp`. It has its own ServiceAccount and serves Streamable HTTP through the internal gateway. OpenCode's manifests use the same server through `http://kubernetes-mcp.developer.svc.cluster.local:8080/mcp`, without the public portal or a local MCP subprocess. Its Home Assistant connection is unchanged.

The Argo CD server is defined in `cluster/developer/argocd-mcp`. It runs native HTTP transport from `argocd-mcp@0.9.0` with `MCP_READ_ONLY=true`. Its dedicated Argo CD account has API-key capability only and is bound to `role:readonly`. The account and RBAC configuration must reach `main` and sync before issuing a token.

The static Argo CD token is stored only in the Cloudflare upstream server's encrypted credentials, not in Git, 1Password, or a Kubernetes workload Secret. Configure authentication type **Bearer** with the JSON-encoded custom-header form `{"headers":{"x-argocd-api-token":"<token>"}}`. Cloudflare supplies this header on upstream requests; the MCP pod has no token environment variable. The token has no automatic expiry. Rotate it by issuing a replacement, updating Cloudflare's encrypted credentials, and revoking the old account token. Cloudflare's API does not permit changing a server's authentication type in place; choose Bearer when creating this registration.

The Cloudflare server uses its own upstream OAuth connection. In **Zero Trust → Access controls → MCP Portals → MCP servers**, connect or re-authenticate **Cloudflare** and approve the required account permissions. This one-time administrator approval is separate from login to the personal portal. Until approval completes, the server remains waiting and its tools are unavailable. A local MCP client's existing OAuth session does not transfer to the portal.

For the initial rollout, deploy the new Kubernetes MCP app before applying the OpenCode migration. Argo CD discovers the new app directory after the manifests reach `main`.

Cloudflare configuration is managed through the Cloudflare API or dashboard, not by Argo CD:

- Account: `d6d3937679a6366e10e8914df0a191b2`; portal ID: `personal`.
- DNS: proxied CNAME `mcp.btkostner.io` → `gateway.agents.cloudflare.com`. Do not put the portal under the private `btkostner.network` route.
- Both the portal and each server have an Access application. The reusable **Personal MCP access** policy permits only `btkostner@gmail.com`, through the existing Cloudflare identity provider.
- Managed OAuth is enabled. Access tokens last 15 minutes; refresh grants last 14 days. Clients must support OAuth token refresh to avoid repeated login prompts.
- Dynamic client registration accepts localhost and loopback callbacks, plus HTTPS callbacks on `claude.ai`, `chatgpt.com`, `chat.openai.com`, `platform.openai.com`, and `playground.ai.cloudflare.com`. Add the callback URI required by another client to the portal Access application's Managed OAuth settings.
- Gateway routing is enabled on the portal and each private upstream. Kubernetes, Argo CD, and Home Assistant use private hostnames routed through the internal Gateway. No `192.168.2.30/32` CIDR route is required.
- Each portal-server mapping has **Require user auth** off (`on_behalf: false`). Servers use their shared upstream identity or administrator OAuth credential, not a separate upstream login for each client.

The Home Assistant MCP URL has a secret path. Its full value remains in 1Password and Cloudflare's server configuration. Do not copy it into documentation, client configuration, or logs. Cloudflare labels this upstream `unauthenticated` because it does not use an Authorization header; possession of its private URL still grants access.

### Connect a client

For clients with remote MCP and OAuth support, add the portal URL and sign in with the permitted Cloudflare account:

```json
{
  "mcpServers": {
    "personal": {
      "url": "https://mcp.btkostner.io/mcp"
    }
  }
}
```

The surrounding configuration format varies by client. For a local client that supports only stdio MCP, use an OAuth-capable HTTP bridge such as [`mcp-remote`](https://github.com/geelen/mcp-remote):

```json
{
  "mcpServers": {
    "personal": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.btkostner.io/mcp"]
    }
  }
}
```

An LLM product must support MCP, or an MCP bridge, to use this endpoint. A public URL does not add MCP support to a product that has none. Hosted clients cannot run a local stdio bridge.

Cloudflare currently rejects the default Python `urllib` user agent with error 1010. Node, HTTPX, and curl reach the OAuth challenge. The endpoint does not guarantee support for every HTTP client or LLM product.

For unattended clients, create a separate Access service token for each client. Attach a **Service Auth** (`non_identity`) policy for that token to the portal Access application **and every upstream server Access application it needs**. Keep `on_behalf: false`, and send `CF-Access-Client-Id` and `CF-Access-Client-Secret` headers. Keep these values in the client's secret store. No permanent service token is created by this setup.

### Add a server

1. Deploy a Streamable HTTP MCP endpoint. Private portal connections through Gateway do not support legacy SSE-only servers. A stdio-only server needs an HTTP wrapper.
2. Make private endpoints reachable through a private hostname route or a narrow CIDR route. Keep credentials in 1Password, the upstream OAuth provider, or Cloudflare's encrypted upstream credentials.
3. In **Zero Trust → Access controls → MCP Portals → MCP servers**, register the URL, configure its authentication, and enable **Route traffic through Cloudflare Gateway**. Wait for **Ready**.
4. Add an Access application of type `mcp`, with a `via_mcp_server_portal` destination for the server ID. Attach **Personal MCP access**, and any required client-specific Service Auth policies.
5. Add the server to portal `personal`. Select the tools and permissions intentionally. Keep **Require user auth** off for shared private credentials; enable it when a server needs each user's upstream OAuth identity.
6. Start a new client session, or use the portal's server-selection tools, to enable the new server. Verify a read through the portal, not only the server's sync status.

Tools are prefixed with their server ID, so names do not collide. The portal enables Code Mode by default to reduce the tool definitions sent to the model. Clients that need normal tool definitions can use `https://mcp.btkostner.io/mcp?codemode=off`.

## Public Network

For public networking it's a pretty standard Kubernetes setup. One _abnormal_ thing about my setup is I use the new (and totally awesome) [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io). There is a single `external-gateway` resource that uses [MetalLB](https://metallb.universe.tf) to allocate the `192.68.3.50` IP address to it. Port forwarding with Ubiquiti allows my house public IP address to accept traffic and route to my cluster services.

To make this fully work, a ddns job on the cluster keeps the `abraxis.tv` Cloudflare records pointed at my house public IP address. `btkostner.network` has no public records and is only reachable through Cloudflare Zero Trust.
