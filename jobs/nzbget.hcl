job "nzbget" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "nzbget" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 6789
      }
    }

    service {
      name = "nzbget"
      port = 6789

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

    volume "config" {
      type            = "csi"
      source          = "nzbget-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "download" {
      type            = "csi"
      source          = "download"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "nzbget" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/nzbget:latest"
        ports = ["http"]

        privileged = true
      }

      env {
        PUID     = 1000
        PGID     = 1000
        TZ       = "America/Denver"
      }

      resources {
        cpu    = 4000
        memory = 2048
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      volume_mount {
        volume      = "download"
        destination = "/download"
      }
    }

    task "openvpn" {
      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      driver = "docker"

      config {
        image = "dperson/openvpn-client"

        cap_add = ["NET_ADMIN"]

        volumes = [
          "local/vpn.conf:/vpn/vpn.conf",
        ]

        devices = [{
          host_path = "/dev/net/tun"
          container_path = "/dev/net/tun"
        }]

        privileged = true
      }

      env {
        FIREWALL = ""
        ROUTE_1  = "192.168.0.0/16"
        ROUTE_2  = "100.64.0.0/10"
        TZ       = "America/Denver"
      }

      template {
        data = <<EOF
VPN_AUTH="{{ key "protonvpn/username" }};{{ key "protonvpn/password" }}"
EOF

        destination = "secrets/file.env"
        env         = true
      }

      template {
        data = <<EOF
{{ key "protonvpn/config" }}
EOF

        destination = "local/vpn.conf"
      }
    }
  }
}
