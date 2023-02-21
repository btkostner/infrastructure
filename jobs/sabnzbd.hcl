job "sabnzbd" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "sabnzbd" {
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
      name = "sabnzbd"
      port = 8080

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
      source          = "sabnzbd-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "download" {
      type            = "csi"
      source          = "download"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "sabnzbd" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/sabnzbd:latest"
        ports = ["http"]

        privileged = true
        network_mode = "container:vpn-${NOMAD_ALLOC_ID}"
      }

      env {
        PUID     = 1000
        PGID     = 1000
        TZ       = "America/Denver"
      }

      resources {
        cpu    = 10000
        memory = 16384
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

    task "vpn" {
      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      driver = "docker"

      config {
        image = "qmcgaw/gluetun"

        cap_add = ["NET_ADMIN", "SYS_MODULE"]

        devices = [{
          host_path = "/dev/net/tun"
          container_path = "/dev/net/tun"
        }]

        privileged = true
      }

      template {
        data = <<EOF
VPN_SERVICE_PROVIDER=custom
VPN_TYPE=wireguard
VPN_ENDPOINT_IP={{ key "protonvpn/sabnzbd/endpoint" }}
VPN_ENDPOINT_PORT={{ key "protonvpn/sabnzbd/port" }}
WIREGUARD_PUBLIC_KEY={{ key "protonvpn/sabnzbd/public_key" }}
WIREGUARD_PRIVATE_KEY={{ key "protonvpn/sabnzbd/private_key" }}
WIREGUARD_ADDRESSES={{ key "protonvpn/sabnzbd/addresses" }}
DOT=off
DNS_KEEP_NAMESERVER=on
FIREWALL=on
FIREWALL_OUTBOUND_SUBNETS="192.168.0.0/16,100.64.0.0/10"
HEALTH_VPN_DURATION_INITIAL=30s
HEALTH_VPN_DURATION_ADDITION=10s
TZ="America/Denver"
EOF

        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
