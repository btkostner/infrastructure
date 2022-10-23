job "loki" {
  namespace   = "monitoring"
  datacenters = ["cluster"]
  type        = "service"

  group "loki" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        static = 3100
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
      name = "loki"
      port = "http"

      connect {
        sidecar_service {}

        sidecar_task {
          resources {
            cpu    = 20
            memory = 64
          }
        }
      }

      check {
        type     = "http"
        path     = "/ready"
        interval = "10s"
        timeout  = "2s"

        check_restart {
          limit = 2
          grace = "60s"
          ignore_warnings = false
        }
      }
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

      resources {
        cpu    = 50
        memory = 32
      }

      template {
        change_mode = "noop"
        destination = "local/alerts.yml"
        data = <<EOH
---
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h
  max_chunk_age: 1h
  chunk_target_size: 1048576
  chunk_retain_period: 30s
  max_transfer_retries: 0
  wal:
    dir: /alloc/data/loki/wal

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /alloc/data/loki/boltdb-shipper-active
    cache_location: /alloc/data/loki/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  filesystem:
    directory: /alloc/data/loki/chunks

compactor:
  working_directory: /alloc/data/loki/boltdb-shipper-compactor
  shared_store: filesystem

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s

ruler:
  storage:
    type: local
    local:
      directory: /alloc/data/loki/rules
  rule_path: /alloc/data/loki/rules-temp
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
EOH
      }
    }
  }
}
