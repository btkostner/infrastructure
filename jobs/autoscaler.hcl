job "autoscaler" {
  namespace = "monitor"
  datacenters = ["cluster"]
  type = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "autoscaler" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 8080
      }
    }

    service {
      name = "autoscaler"
      port = 8080

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "nomad-server"
              local_bind_port = 4646
            }

            upstreams {
              destination_name = "prometheus"
              local_bind_port = 9090
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
        path     = "/v1/health"
        interval = "10s"
        timeout  = "2s"
      }

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
      }
    }

    task "autoscaler" {
      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler:0.3.7"
        command = "nomad-autoscaler"
        args    = ["agent", "-config", "local/config.hcl"]
        ports   = ["autoscaler"]
      }

      template {
        data = <<EOF
http {
  bind_address = "0.0.0.0"
  bind_port    = {{ env "NOMAD_PORT_http" }}
}

nomad {
  address = "http://{{ env "NOMAD_IP_http" }}:4646"
}

apm "nomad-apm" {
  driver = "nomad-apm"
}

apm "prometheus" {
  driver = "prometheus"
  config = {
    address = "http://{{ env "NOMAD_UPSTREAM_ADDR_prometheus" }}"
  }
}

strategy "pass-through" {
  driver = "pass-through"
}

strategy "target-value" {
  driver = "target-value"
}
EOF

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config.hcl"
      }
    }
  }
}
