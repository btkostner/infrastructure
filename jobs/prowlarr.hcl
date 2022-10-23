job "prowlarr" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  group "prowlarr" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        static = 9696
      }
    }

    service {
      name = "prowlarr"
      tags = ["urlprefix-/"]
      port = "http"
    }

    volume "store" {
      type            = "csi"
      source          = "prowlarr"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "server" {
      driver = "docker"

      config {
        image = "linuxserver/prowlarr:develop"
        ports = ["http"]
      }

      volume_mount {
        volume      = "store"
        destination = "/config"
      }
    }
  }
}
