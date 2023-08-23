job "sonarr" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "sonarr" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 8989
      }

      port "metrics" {}
    }

    service {
      name = "sonarr"
      port = 8989

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "autoscan"
              local_bind_port  = 3030
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
      source          = "sonarr-config"
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

    task "sonarr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/sonarr:latest"
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
        cpu    = 2000
        memory = 4096
      }

      template {
        data = <<EOF
<Config>
  <LogLevel>info</LogLevel>
  <UrlBase />
  <Branch>main</Branch>
  <ApiKey>{{ key "download/sonarr" }}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <InstanceName>Sonarr</InstanceName>
  <Port>{{ env "NOMAD_ALLOC_PORT_http" }}</Port>
  <BindAddress>*</BindAddress>
  <LaunchBrowser>False</LaunchBrowser>
  <EnableSsl>False</EnableSsl>
  <SslPort>6969</SslPort>
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
        image = "ghcr.io/onedr0p/exportarr:v1.5.3"
        args = ["sonarr"]
        ports = ["metrics"]
      }

      template {
        data = <<EOF
PORT="{{ env "NOMAD_ALLOC_PORT_metrics" }}"
URL="http://localhost:8989"
API_KEY="{{ key "download/sonarr" }}"
ENABLE_ADDITIONAL_METRICS="true"
EOF

        destination = "secrets/file.env"
        env         = true
      }
    }
  }
}
