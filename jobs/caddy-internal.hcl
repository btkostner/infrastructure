job "caddy-internal" {
  namespace   = "network"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "caddy" {
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

      port "health" {
        to = 8081
      }
    }

    service {
      name = "caddy-internal"
      port = 443

      check {
        address_mode = "alloc"
        name = "Health Endpoint"
        type = "http"
        port = "health"
        path = "/health"
        interval = "10s"
        timeout = "2s"
      }

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "bazarr"
              local_bind_port = 6767
            }

            upstreams {
              destination_name = "grafana"
              local_bind_port = 3000
            }

            upstreams {
              destination_name = "lidarr"
              local_bind_port = 8686
            }

            upstreams {
              destination_name = "nzbget"
              local_bind_port = 6789
            }

            upstreams {
              destination_name = "overseerr"
              local_bind_port = 5055
            }

            upstreams {
              destination_name = "plex"
              local_bind_port = 32400
            }

            upstreams {
              destination_name = "prowlarr"
              local_bind_port = 9696
            }

            upstreams {
              destination_name = "radarr"
              local_bind_port = 7878
            }

            upstreams {
              destination_name = "sabnzbd"
              local_bind_port = 8080
            }

            upstreams {
              destination_name = "sonarr"
              local_bind_port = 8989
            }

            upstreams {
              destination_name = "tautulli"
              local_bind_port = 8181
            }
          }
        }

        sidecar_task {
          env {
            ENVOY_UID = "0"
          }
        }
      }

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
      }
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
        image = "ghcr.io/btkostner/caddy"
        args = ["caddy", "run", "--config=$${NOMAD_TASK_DIR}/Caddyfile"]
        ports = ["http", "https"]
      }

      template {
        change_mode = "signal"
        change_signal = "SIGHUP"
        destination = "$${NOMAD_TASK_DIR}/Caddyfile"

        data = <<EOF
{
  acme_dns cloudflare {{ key "cloudflare/api_key" }}

  storage consul {
    address      "{{ env "NOMAD_IP_http" }}:8500"
    prefix       "caddy-internal"
  }
}

consul.btkostner.network {
  reverse_proxy 192.168.1.152:8500
}

bazarr.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_bazarr" }}
}

home.btkostner.network {
  reverse_proxy {{range service "home-assistant"}}{{.Address}}:{{.Port}}{{end}}
}

grafana.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_grafana" }}
}

lidarr.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_lidarr" }}
}

nomad.btkostner.network {
  reverse_proxy 192.168.1.152:4646
}

nzbget.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_nzbget" }}
}

overseerr.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_overseerr" }}
}

plex.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_plex" }}
}

prowlarr.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_prowlarr" }}
}

radarr.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_radarr" }}
}

sabnzbd.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_sabnzbd" }}
}

sonarr.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_sonarr" }}
}

tautulli.btkostner.network {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_tautulli" }}
}

http://0.0.0.0:8081 {
  respond "Success"
}

:80, :443 {
  respond 404
}
EOF
      }

      resources {
        cpu    = 100
        memory = 128
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
    }
  }
}
