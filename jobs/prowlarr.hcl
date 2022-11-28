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
              destination_name = "radarr"
              local_bind_port  = 7878
            }

            upstreams {
              destination_name = "sonarr"
              local_bind_port  = 8989
            }

            upstreams {
              destination_name = "nzbget"
              local_bind_port  = 6789
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

      resources {
        cpu    = 20
        memory = 64
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
