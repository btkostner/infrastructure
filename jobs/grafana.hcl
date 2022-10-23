job "grafana" {
  namespace   = "monitoring"
  datacenters = ["cluster"]
  type        = "service"

  group "grafana" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        static = 8000
      }
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "10s"
      mode     = "delay"
    }

    ephemeral_disk {
      sticky = true
      size = 1024
      migrate = true
    }

    service {
      name = "grafana"
      tags = ["urlprefix-/"]
      port = "http"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "alert-manager"
              local_bind_port  = 9093
            }

            upstreams {
              destination_name = "prometheus"
              local_bind_port = 9090
            }

            upstreams {
              destination_name = "loki"
              local_bind_port = 3100
            }
          }
        }

        sidecar_task {
          resources {
            cpu    = 20
            memory = 64
          }
        }
      }

      check {
        type     = "http"
        path     = "/api/health"
        interval = "5s"
        timeout  = "2s"

        check_restart {
          limit = 2
          grace = "60s"
          ignore_warnings = false
        }
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:latest"

        volumes = [
          "local/prometheus.yml:/local/provisioning/datasources/prometheus.yml",
        ]
      }

      env {
        GF_LOG_LEVEL = "DEBUG"
        GF_LOG_MODE = "console"
        GF_PATHS_DATA = "/alloc/data/grafana"
        GF_PATHS_PROVISIONING = "/local/provisioning"
        GF_SERVER_HTTP_PORT = "${NOMAD_PORT_http}"
        GF_DEFAULT_INSTANCE_NAME = "btkostner"
        GF_SECURITY_ADMIN_USER = "{{ env \"grafana/btkostner\" }}"
        GF_SECURITY_ADMIN_PASSWORD = "{{ env \"grafana/password\" }}"
        GF_METRICS_ENABLED = "true"
        GF_METRICS_DISABLE_TOTAL_STATS = "false"
      }

      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"

        data = <<EOH
---
apiVersion: 1

deleteDatasources:
  - name: Prometheus
    orgId: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    orgId: 1
    url: http://localhost:9090
    isDefault: true
    version: 1
    editable: false
EOH
      }

      resources {
        cpu    = 100
        memory = 300
      }
    }
  }
}
