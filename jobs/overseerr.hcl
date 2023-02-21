job "overseerr" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  group "overseerr" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 5055
      }
    }

    service {
      name = "overseerr"
      port = 5055

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "plex"
              local_bind_port  = 32400
            }

            upstreams {
              destination_name = "radarr"
              local_bind_port  = 7878
            }

            upstreams {
              destination_name = "sonarr"
              local_bind_port  = 8989
            }

            upstreams {
              destination_name = "tautulli"
              local_bind_port  = 8181
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

    volume "config" {
      type            = "csi"
      source          = "overseerr-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "overseerr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/overseerr:latest"
        ports = ["http"]

        privileged = true
      }

      env {
        PUID     = 1000
        PGID     = 1000
        TZ       = "America/Denver"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }
    }
  }
}
