job "alert-manager" {
  namespace   = "monitoring"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "alert-manager" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        static = 9093
      }
    }

    service {
      name = "alert-manager"
      port = "http"
      tags = ["urlprefix-/alertmanager strip=/alertmanager"]

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
        path     = "/-/healthy"
        interval = "3s"
        timeout  = "1s"
      }
    }

    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager:latest"

        args = [
          "--config.file=/etc/alertmanager/config/alertmanager.yml",
        ]

        volumes = [
          "local/config:/etc/alertmanager/config",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }

      template {
        data = <<EOH
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'web.hook'
receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/alertmanager.yml"
      }
    }
  }
}
