job "plex" {
  namespace   = "media"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "true"
  }

  group "plex" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 32400
      }
    }

    service {
      name = "plex"
      port = 32400

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }
          }
        }

        sidecar_task {
          env {
            ENVOY_UID = "0"
          }
        }
      }

      check {
        type     = "http"
        port     = "http"
        path     = "/identity"
        interval = "10s"
        timeout  = "5s"

        check_restart {
          limit = 5
          grace = "120s"
          ignore_warnings = false
        }
      }

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
      }
    }

    volume "config" {
      type            = "csi"
      source          = "plex-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "media" {
      type            = "csi"
      source          = "media"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "plex" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/plex:latest"

        devices = [{
          host_path = "/dev/dri"
          container_path = "/dev/dri"
        }]

        privileged = true
      }

      env {
        VERSION = "latest"
        TZ      = "America/Denver"
      }

      resources {
        cpu    = 10000
        memory = 12288
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      volume_mount {
        volume      = "media"
        destination = "/media"
      }
    }
  }
}
