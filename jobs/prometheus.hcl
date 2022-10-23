job "prometheus" {
  namespace   = "monitoring"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "prometheus" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        static = 9090
      }
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "10s"
      mode     = "fail"
    }

    ephemeral_disk {
      sticky = true
      size = 5120
      migrate = true
    }

    service {
      name = "prometheus"
      port = "http"
      tags = ["urlprefix-/"]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "alert-manager"
              local_bind_port  = 9093
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
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:latest"
        ports = ["http"]

        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/alloc/data/tsdb",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles"
        ]

        volumes = [
          "local/alerts.yml:/etc/prometheus/alerts.yml",
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]
      }

      template {
        change_mode = "noop"
        destination = "local/alerts.yml"
        data = <<EOH
---
groups:
  - name: prometheus_alerts
    rules: []
EOH
      }

      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"

        data = <<EOH
---
global:
  scrape_interval: 5s
  evaluation_interval: 5s
alerting:
  alertmanagers:
    - consul_sd_configs:
        - server: '{{ env "NOMAD_IP_http" }}:8500'
          services:
            - alert-manager
rule_files:
  - alerts.yml
scrape_configs:
  - job_name: consul
    static_configs:
      - targets:
          - '{{ env "NOMAD_IP_http" }}:8500'
    honor_timestamps: true
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /v1/agent/metrics
    scheme: http
    params:
      format:
        - prometheus
  - job_name: nomad
    consul_sd_configs:
      - server: '{{ env "NOMAD_IP_http" }}:8500'
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
  - job_name: alert-manager
    consul_sd_configs:
      - server: '{{ env "NOMAD_IP_http" }}:8500'
        services:
          - alert-manager
  - job_name: grafana
    consul_sd_configs:
      - server: '{{ env "NOMAD_IP_http" }}:8500'
        services:
          - grafana
EOH
      }
    }
  }
}
