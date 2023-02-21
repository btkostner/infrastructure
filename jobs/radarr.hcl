job "radarr" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "radarr" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 7878
      }

      port "metrics" {}
    }

    service {
      name = "radarr"
      port = 7878

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "prowlarr"
              local_bind_port  = 9696
            }

            upstreams {
              destination_name = "sabnzbd"
              local_bind_port  = 8080
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
        http_metrics_port = "${NOMAD_HOST_PORT_metrics}"
      }
    }

    volume "config" {
      type            = "csi"
      source          = "radarr-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "download" {
      type            = "csi"
      source          = "download"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    volume "media" {
      type            = "csi"
      source          = "media"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "radarr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/radarr:latest"
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
        cpu    = 3000
        memory = 2048
      }

      template {
        data = <<EOF
<Config>
  <LogLevel>info</LogLevel>
  <UrlBase />
  <Branch>master</Branch>
  <ApiKey>{{ key "download/radarr" }}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <InstanceName>Radarr</InstanceName>
  <Port>{{ env "NOMAD_ALLOC_PORT_http" }}</Port>
  <BindAddress>*</BindAddress>
  <LaunchBrowser>False</LaunchBrowser>
  <EnableSsl>False</EnableSsl>
  <SslPort>6969</SslPort>
  <SslCertPath />
  <SslCertPassword />
  <UpdateMechanism>Docker</UpdateMechanism>
</Config>
EOF

        destination = "local/config.xml"
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      volume_mount {
        volume      = "download"
        destination = "/download"
      }

      volume_mount {
        volume      = "media"
        destination = "/media"
      }
    }

    task "metrics" {
      lifecycle {
        sidecar = true
      }

      driver = "docker"

      config {
        image = "ghcr.io/onedr0p/exportarr:latest"
        args = ["radarr"]
        ports = ["metrics"]
      }

      template {
        data = <<EOF
PORT="{{ env "NOMAD_ALLOC_PORT_metrics" }}"
URL="http://localhost:7878"
APIKEY="{{ key "download/radarr" }}"
EOF

        destination = "secrets/file.env"
        env         = true
      }
    }
  }
}
