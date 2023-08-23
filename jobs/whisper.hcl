job "whisper" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "whisper" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 9000
      }
    }

    service {
      name = "whisper"
      port = 9000

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
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
      }
    }

    task "whisper" {
      driver = "docker"

      config {
        image = "docker.io/onerahmet/openai-whisper-asr-webservice:latest"
        ports = ["http"]

        devices = [{
          host_path = "/dev/dri"
          container_path = "/dev/dri"
        }]

        privileged = true
      }

      env {
        PUID       = 1000
        PGID       = 1000
        TZ         = "America/Denver"
        ASR_MODEL  = "base"
        ASR_ENGINE = "faster_whisper"
      }

      resources {
        cpu    = 4000
        memory = 4096
      }
    }
  }
}
