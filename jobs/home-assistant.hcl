job "home-assistant" {
  namespace   = "home-assistant"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "home-assistant" {
    network {
      mode = "host"

      port "http" {
        static = 8123
        to = 8123
      }
    }

    service {
      name = "home-assistant"
      port = "http"
      address_mode = "host"
    }

    volume "config" {
      type            = "csi"
      source          = "home-assistant-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "home-assistant" {
      driver = "docker"

      config {
        image        = "ghcr.io/home-assistant/home-assistant:stable"
        network_mode = "host"
        privileged   = true
      }

      env {
        PUID     = 1000
        PGID     = 1000
        TZ       = "America/Denver"
      }

      resources {
        cpu    = 4000
        memory = 4096
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }
    }
  }
}
