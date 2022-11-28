job "loki" {
  namespace   = "monitor"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "loki" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 3100
      }
    }

    service {
      name = "loki"
      port = 3100

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
        path     = "/ready"
        interval = "10s"
        timeout  = "2s"

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

    volume "data" {
      type            = "csi"
      source          = "loki-data"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:2.6.1"

        args = [
          "-config.file=/etc/loki/local-config.yaml"
        ]

        volumes = [
          "local/local-config.yml:/etc/loki/local-config.yml",
        ]
      }

      volume_mount {
        volume      = "data"
        destination = "/data"
      }

      template {
        change_mode = "noop"
        destination = "local/local-config.yml"
        data = <<EOH
---
auth_enabled: false

server:
  http_listen_port: {{ env "NOMAD_ALLOC_PORT_http" }}

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  max_chunk_age: 30s

schema_config:
  configs:
    - from: 2020-05-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
    directory: /data/index

  filesystem:
    directory: /data/index

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
EOH
      }
    }
  }
}
