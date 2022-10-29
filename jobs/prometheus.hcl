job "prometheus" {
  namespace   = "monitor"
  datacenters = ["cluster"]
  type        = "service"

  group "prometheus" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        static = 9090
        to = 9090
      }
    }

    service {
      name = "prometheus"
      tags = ["urlprefix-/"]
      port = 9090

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "grafana"
              local_bind_port  = 8000
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

      check {
        type     = "http"
        port     = "http"
        path     = "/-/healthy"
        interval = "5s"
        timeout  = "2s"

        check_restart {
          limit = 5
          grace = "120s"
          ignore_warnings = false
        }
      }
    }

    volume "data" {
      type            = "csi"
      source          = "prometheus-data"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "prometheus" {
      driver = "docker"
      user   = "root"

      config {
        image = "prom/prometheus:latest"
        ports = ["http"]

        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/data",
          "--storage.tsdb.retention.time=365d",
          "--storage.tsdb.retention.size=50GB",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles"
        ]

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]
      }

      template {
        data = <<EOH
---
global:
  scrape_interval: 5s
  evaluation_interval: 5s
scrape_configs:
  - job_name: consul
    static_configs:
      - targets:
          - "{{ env "NOMAD_IP_http" }}:8500"
    honor_timestamps: true
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /v1/agent/metrics
    scheme: http
    params:
      format:
        - prometheus
  - job_name: consul-connect-envoy
    consul_sd_configs:
      - server: "{{ env "NOMAD_IP_http" }}:8500"
    relabel_configs:
      - source_labels: [__meta_consul_service]
        regex: (.+)-sidecar-proxy
        action: drop
      - source_labels: [__meta_consul_service_metadata_envoy_metrics_port]
        regex: (.+)
        action: keep
      - source_labels: [__address__,__meta_consul_service_metadata_envoy_metrics_port]
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $${1}:$${2}
        target_label: __address__
    honor_timestamps: true
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /metrics
    scheme: http
  - job_name: nomad
    consul_sd_configs:
      - server: "{{ env "NOMAD_IP_http" }}:8500"
        services:
          - nomad-servers
          - nomad-clients
    relabel_configs:
      - source_labels:
          - __meta_consul_tags
        regex: (.*)http(.*)
        action: keep
    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format:
        - prometheus
  - job_name: grafana
    static_configs:
      - targets:
          - "{{ env "NOMAD_UPSTREAM_ADDR_grafana" }}"
    scrape_interval: 5s
    metrics_path: /metrics
    params:
      format:
        - prometheus
EOH

        destination = "local/prometheus.yml"
      }

      resources {
        cpu        = 500
        memory     = 300
        memory_max = 400
      }

      volume_mount {
        volume      = "data"
        destination = "/data"
      }
    }
  }
}
