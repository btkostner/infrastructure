job "autoscan" {
  namespace   = "media"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "autoscan" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 3030
      }
    }

    service {
      name = "autoscan"
      port = 3030

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "plex"
              local_bind_port  = 32400
            }
          }
        }

        sidecar_task {
          env {
            ENVOY_UID = "0"
          }
        }
      }

      check {
        type     = "http"
        port     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "5s"

        check_restart {
          limit = 5
          grace = "120s"
          ignore_warnings = false
        }
      }
    }

    volume "media" {
      type            = "csi"
      source          = "media"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "autoscan" {
      driver = "docker"

      config {
        image = "docker.io/cloudb0x/autoscan:latest"
        ports = ["http"]

        volumes = [
          "local/config.yml:/config/config.yml",
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
port: {{ env "NOMAD_ALLOC_PORT_http" }}

scan-delay: 15s

targets:
  plex:
    - url: http://localhost:32400
      token: "{{ key "plex/token" }}"
      verbosity: debug

triggers:
  manual:
    priority: 5

  lidarr:
    - name: lidarr
      priority: 2

      rewrite:
        - from: /music
          to: /media/music

  radarr:
    - name: radarr
      priority: 3

  sonarr:
    - name: sonarr
      priority: 4
EOF

        destination = "local/config.yml"
      }

      volume_mount {
        volume      = "media"
        destination = "/media"
      }
    }
  }
}
