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
              destination_name = "nzbget"
              local_bind_port  = 6789
            }

            upstreams {
              destination_name = "prowlarr"
              local_bind_port  = 9696
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
        cpu    = 4000
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
  }
}
