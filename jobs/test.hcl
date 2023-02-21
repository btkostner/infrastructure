job "test" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  group "test" {
    task "bash" {
      driver = "docker"

      config {
        image = "alpine"
        command = "/bin/sh"
        args = ["-c", "while sleep 3600; do :; done"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
