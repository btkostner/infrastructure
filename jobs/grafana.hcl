job "grafana" {
  namespace   = "monitor"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "grafana" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 3000
      }
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "10s"
      mode     = "delay"
    }

    service {
      name = "grafana"
      port = 3000

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
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
          env {
            ENVOY_UID = "0"
          }
        }
      }

      check {
        type     = "http"
        port     = "http"
        path     = "/api/health"
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

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:latest"
        ports = ["http"]

        volumes = [
          "local/provider.yml:/local/provisioning/datasources/default.yml",
          "local/dashboard.yml:/local/provisioning/dashboards/default.yml",
          "local/plugin.yml:/local/provisioning/plugins/default.yml",
        ]
      }

      env {
        GF_LOG_LEVEL = "DEBUG"
        GF_LOG_MODE = "console"
        GF_PATHS_PROVISIONING = "/local/provisioning"
        GF_DEFAULT_INSTANCE_NAME = "btkostner"
        GF_METRICS_ENABLED = "true"
        GF_METRICS_DISABLE_TOTAL_STATS = "false"
        GF_INSTALL_PLUGINS = "grafana-piechart-panel"
      }

      template {
        data = <<EOF
GF_SERVER_HTTP_PORT="{{ env "NOMAD_ALLOC_PORT_http" }}"
GF_SERVER_DOMAIN=grafana.btkostner.network
GF_DEFAULT_INSTANCE_NAME=btkostner
GF_SECURITY_ADMIN_USER=btkostner
GF_SECURITY_ADMIN_PASSWORD="{{ key "grafana/password" }}"
GF_LOG_MODE=console
EOF

        destination = "secrets/file.env"
        env         = true
      }

      artifact {
        source      = "git::https://github.com/btkostner/infrastructure.git//dashboards"
        destination = "/local/dashboards"
        mode        = "dir"
      }

      template {
        change_mode = "noop"
        destination = "local/provider.yml"

        data = <<EOH
---
apiVersion: 1

deleteDatasources:
  - name: Prometheus
    orgId: 1
  - name: Loki
    orgId: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    orgId: 1
    url: "http://{{ env "NOMAD_UPSTREAM_ADDR_prometheus" }}"
    isDefault: true
    version: 1
    editable: false
  - name: Loki
    type: loki
    access: proxy
    orgId: 1
    url: "http://{{ env "NOMAD_UPSTREAM_ADDR_loki" }}"
    version: 1
    editable: false
EOH
      }

      template {
        change_mode = "noop"
        destination = "local/dashboard.yml"

        data = <<EOH
---
apiVersion: 1

providers:
  - name: dashboards
    type: file
    disableDeletion: true
    allowUiUpdates: false
    options:
      path: /local/dashboards
      foldersFromFilesStructure: true
EOH
      }

      template {
        change_mode = "noop"
        destination = "local/plugin.yml"

        data = <<EOH
---
apiVersion: 1

apps:
  - type: grafana-piechart-panel
    org_id: 1
EOH
      }
    }
  }
}
