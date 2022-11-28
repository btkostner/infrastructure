job "tautulli" {
  namespace   = "media"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "tautulli" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 8181
      }

      port "metrics" {
        to = 9487
      }
    }

    service {
      name = "tautulli"
      port = 8181

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
        http_metrics_port = "${NOMAD_HOST_PORT_metrics}"
      }
    }

    volume "config" {
      type            = "csi"
      source          = "tautulli-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "tautulli" {
      driver = "docker"

      config {
        image = "ghcr.io/tautulli/tautulli:latest"
        ports = ["http"]

        privileged = true
      }

      env {
        PUID     = 1000
        PGID     = 1000
        TZ       = "America/Denver"
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }
    }


    task "metrics" {
      lifecycle {
        sidecar = true
      }

      driver = "docker"

      config {
        image = "nwalke/tautulli_exporter:latest"
        ports = ["metrics"]
      }

      template {
        data = <<EOF
SERVE_PORT="{{ env "NOMAD_ALLOC_PORT_metrics" }}"
TAUTULLI_URI="http://localhost:8181"
TAUTULLI_API_KEY="{{ key "download/tautulli" }}"
EOF

        destination = "secrets/file.env"
        env         = true
      }
    }
  }
}
