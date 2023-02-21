job "ddns" {
  namespace = "network"
  datacenters = ["cluster"]
  type = "service"

  group "ddclient" {
    task "ddclient" {
      driver = "docker"

      config {
        image   = "lscr.io/linuxserver/ddclient:latest"

        volumes = [
          "local/ddclient.conf:/config/ddclient.conf"
        ]

        privileged = true
      }

      env {
        TZ       = "America/Denver"
      }

      template {
        destination   = "local/ddclient.conf"

        data = <<EOF
daemon=600
syslog=yes
verbose=no
ssl=yes
use=web, web=checkip.amazonaws.com/

protocol=cloudflare, \
zone=abraxis.tv, \
login={{ key "cloudflare/email" }}, \
password={{ key "cloudflare/global_api_key" }} \
abraxis.tv, request.abraxis.tv, home.lizandblake.us
EOF
      }
    }
  }
}
