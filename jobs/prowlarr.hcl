job "prowlarr" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "prowlarr" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 9696
      }

      port "metrics" {}
    }

    service {
      name = "prowlarr"
      port = 9696

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "lidarr"
              local_bind_port  = 8686
            }

            upstreams {
              destination_name = "sabnzbd"
              local_bind_port  = 8080
            }

            upstreams {
              destination_name = "radarr"
              local_bind_port  = 7878
            }

            upstreams {
              destination_name = "sonarr"
              local_bind_port  = 8989
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
        # http_metrics_port = "${NOMAD_HOST_PORT_metrics}"
      }
    }

    volume "config" {
      type            = "csi"
      source          = "prowlarr-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "prowlarr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/prowlarr:develop"
        ports = ["http"]

        volumes = [
          "local/config.xml:/config/config.xml",
        ]

        privileged = true
        network_mode = "container:vpn-${NOMAD_ALLOC_ID}"
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

      template {
        data = <<EOF
<Config>
  <LogLevel>info</LogLevel>
  <UrlBase></UrlBase>
  <UpdateMechanism>Docker</UpdateMechanism>
  <AuthenticationMethod>None</AuthenticationMethod>
  <ApiKey>{{ key "download/prowlarr" }}</ApiKey>
  <Branch>develop</Branch>
  <BindAddress>*</BindAddress>
  <Port>{{ env "NOMAD_ALLOC_PORT_http" }}</Port>
  <SslPort>6969</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <SslCertPath></SslCertPath>
  <SslCertPassword></SslCertPassword>
  <InstanceName>Prowlarr</InstanceName>
</Config>
EOF

        destination = "local/config.xml"
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
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
VPN_ENDPOINT_IP={{ key "protonvpn/prowlarr/endpoint" }}
VPN_ENDPOINT_PORT={{ key "protonvpn/prowlarr/port" }}
WIREGUARD_PUBLIC_KEY={{ key "protonvpn/prowlarr/public_key" }}
WIREGUARD_PRIVATE_KEY={{ key "protonvpn/prowlarr/private_key" }}
WIREGUARD_ADDRESSES={{ key "protonvpn/prowlarr/addresses" }}
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

  /**
    task "metrics" {
      lifecycle {
        sidecar = true
      }

      driver = "docker"

      config {
        image = "ghcr.io/onedr0p/exportarr:latest"
        args = ["prowlarr"]
        ports = ["metrics"]
      }

      template {
        data = <<EOF
PORT="{{ env "NOMAD_ALLOC_PORT_metrics" }}"
URL="http://localhost:9696"
APIKEY="{{ key "download/prowlarr" }}"
EOF

        destination = "secrets/file.env"
        env         = true
      }
    }
    */
  }
}
