job "caddy-internal" {
  namespace   = "network"
  datacenters = ["cluster"]
  type        = "service"

  group "caddy" {
    count = 1

    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 80
      }

      port "https" {
        to = 443
      }
    }

    service {
      name = "caddy-internal"
      tags = ["urlprefix-/"]
      port = 443

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "grafana"
              local_bind_port = 3000
            }
          }
        }

        sidecar_task {
          env {
            ENVOY_UID = "0"
          }

          resources {
            cpu    = 20
            memory = 64
          }
        }
      }

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
      }
    }

    volume "caddy-data" {
      type            = "csi"
      source          = "caddy-internal-data"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "tailscale-data" {
      type            = "csi"
      source          = "caddy-internal-tailscale-data"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "caddy" {
      driver = "docker"

      config {
        image = "slothcroissant/caddy-cloudflaredns:2.6.2"
        args = ["caddy", "run", "--config=$${NOMAD_TASK_DIR}/Caddyfile"]
        ports = ["http", "https"]
      }

      template {
        change_mode = "script"
        destination = "$${NOMAD_TASK_DIR}/Caddyfile"

        change_script {
          command       = "/usr/bin/caddy"
          args          = ["reload"]
          timeout       = "5s"
          fail_on_error = true
        }

        data = <<EOF
consul.btkostner.network {
  reverse_proxy 192.168.1.152:8500

  tls {
    dns cloudflare {{ key "cloudflare" }}
    resolvers 1.1.1.1
  }
}

grafana.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_grafana" }}

  tls {
    dns cloudflare {{ key "cloudflare" }}
    resolvers 1.1.1.1
  }
}

nomad.btkostner.network {
  reverse_proxy 192.168.1.152:4646

  tls {
    dns cloudflare {{ key "cloudflare" }}
    resolvers 1.1.1.1
  }
}
EOF
      }

      volume_mount {
        volume      = "caddy-data"
        destination = "/data"
      }

      resources {
        cpu    = 100
        memory = 300
      }
    }

    task "tailscale" {
      driver = "docker"

      config {
        image = "tailscale/tailscale:stable"
      }

      template {
        data = <<EOF
TS_AUTH_KEY="{{ key "tailscale" }}"
TS_STATE_DIR="/var/lib/tailscale"
TS_EXTRA_ARGS="--hostname=cluster"
EOF

        destination = "secrets/file.env"
        env         = true
      }

      volume_mount {
        volume      = "tailscale-data"
        destination = "/var/lib/tailscale"
      }

      resources {
        cpu    = 100
        memory = 300
      }
    }
  }
}
