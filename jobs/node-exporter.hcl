job "node-exporter" {
  namespace   = "monitor"
  datacenters = ["cluster"]
  type        = "system"

  group "node-exporter" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 9100
      }
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "10s"
      mode     = "delay"
    }

    service {
      name = "node-exporter"
      port = 9100

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
        path     = "/"
        interval = "5s"
        timeout  = "2s"

        check_restart {
          limit = 2
          grace = "60s"
          ignore_warnings = false
        }
      }

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
        http_metrics_port = "${NOMAD_HOST_PORT_http}"
      }
    }

    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter:latest"
        ports = ["http"]

        volumes = [
          "/proc:/host/proc",
          "/sys:/host/sys",
          "/:/rootfs"
        ]
      }

      resources {
        cpu    = 100
        memory = 768
      }
    }
  }
}
