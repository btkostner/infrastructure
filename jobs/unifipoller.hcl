job "unifipoller" {
  namespace   = "monitor"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "unifipoller" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "metrics" {
        to = 9130
      }
    }

    service {
      name = "unifipoller"
      port = 9130

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

      meta {
        application_metrics_port = "${NOMAD_HOST_PORT_metrics}"
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
      }
    }

    task "unifipoller" {
      driver = "docker"

      config {
        image = "ghcr.io/unpoller/unpoller:latest"
        ports = ["metrics"]

        volumes = [
          "local/unifi-poller.conf:/config/unifi-poller.conf"
        ]

        privileged = true
      }

      template {
        data = <<EOF
[poller]
  quiet = true
  debug = false

[unifi]
  dynamic = false

[unifi.defaults]
  url = "https://192.168.1.1"
  user = "{{ key "unifi/username" }}"
  pass = "{{ key "unifi/password" }}"
  save_sites = true
  save_ids = true
  save_alarms = true
  save_anomalies = true
  save_dpi = true

[prometheus]
  disable = false
  http_listen = "0.0.0.0:9130"

[datadog]
  disable = true
EOF

        destination = "local/unifi-poller.conf"
      }

      resources {
        cpu    = 1000
        memory = 1000
      }
    }
  }
}
