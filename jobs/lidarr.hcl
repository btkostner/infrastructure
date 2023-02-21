job "lidarr" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "lidarr" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 8686
      }

      port "metrics" {}
    }

    service {
      name = "lidarr"
      port = 8686

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "sabnzbd"
              local_bind_port  = 8080
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
        http_metrics_port = "${NOMAD_HOST_PORT_metrics}"
      }
    }

    volume "config" {
      type            = "csi"
      source          = "lidarr-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "download" {
      type            = "csi"
      source          = "download"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    volume "music" {
      type            = "csi"
      source          = "music"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "lidarr" {
      driver = "docker"

      config {
        image = "randomninjaatk/lidarr-extended:latest"
        ports = ["http"]

        volumes = [
          "local/config.xml:/config/config.xml"
        ]

        privileged = true
      }

      env {
        autoStart = "true"
        enableAudioScript = "true"
        enableVideoScript = "false"
        scriptInterval = "15m"
        configureLidarrWithOptimalSettings = "true"
        searchSort = "date"
        audioFormat = "native"
        audioBitrate = "lossless"
        requireQuality = "true"
        enableReplaygainTags = "true"
        audioLyricType = "both"
        dlClientSource = "tidal"
        tidalCountryCode = "US"
        youtubeSubtitleLanguage = "en"
        enableQueueCleaner = "true"
        PUID     = 1000
        PGID     = 1000
        TZ       = "America/Denver"
      }

      resources {
        cpu    = 1400
        memory = 1280
      }

      template {
        data = <<EOF
<Config>
  <LogLevel>info</LogLevel>
  <UrlBase />
  <Branch>develop</Branch>
  <ApiKey>{{ key "download/lidarr" }}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <InstanceName>Lidarr</InstanceName>
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
        volume      = "music"
        destination = "/music"
      }
    }

    task "metrics" {
      lifecycle {
        sidecar = true
      }

      driver = "docker"

      config {
        image = "ghcr.io/onedr0p/exportarr:latest"
        args = ["lidarr"]
        ports = ["metrics"]
      }

      template {
        data = <<EOF
PORT="{{ env "NOMAD_ALLOC_PORT_metrics" }}"
URL="http://localhost:8686"
APIKEY="{{ key "download/lidarr" }}"
EOF

        destination = "secrets/file.env"
        env         = true
      }
    }
  }
}
