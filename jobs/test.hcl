job "test" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  group "test" {
    count = 1

    volume "config-new" {
      type            = "csi"
      source          = "prowlarr-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "config-old" {
      type            = "csi"
      source          = "prowlarr-old"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "bash" {
      driver = "docker"

      config {
        image = "ubuntu:latest"
        command = "/bin/bash"
        args = ["-c", "--", "while true; do sleep 30; done;"]
      }

      volume_mount {
        volume      = "config-new"
        destination = "/media/new"
      }

      volume_mount {
        volume      = "config-old"
        destination = "/media/old"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
