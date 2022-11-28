job "caddy-external" {
  namespace   = "network"
  datacenters = ["cluster"]
  type        = "system"

  group "caddy" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 80
        static = 80
      }

      port "https" {
        to = 443
        static = 443
      }
    }

    service {
      name = "caddy-external"
      port = 443

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "overseerr"
              local_bind_port = 5055
            }

            upstreams {
              destination_name = "plex"
              local_bind_port = 32400
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

    task "caddy" {
      driver = "docker"

      config {
        image = "ghcr.io/btkostner/caddy"
        args = ["caddy", "run", "--config=$${NOMAD_TASK_DIR}/Caddyfile"]
        ports = ["http", "https"]
      }

      template {
        change_mode = "script"
        destination = "$${NOMAD_TASK_DIR}/Caddyfile"

        change_script {
          command       = "/usr/bin/caddy"
          args          = ["reload"]
          timeout       = "5s"
          fail_on_error = true
        }

        data = <<EOF
{
  acme_dns cloudflare {{ key "cloudflare/api_key" }}

  storage consul {
    address      "{{ env "NOMAD_IP_http" }}:8500"
    prefix       "caddy-external"
  }
}

abraxis.tv {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_plex" }}
  encode gzip
  header {
    Content-Security-Policy default-src "*"
    X-Frame-Options "DENY"
    X-Content-Type-Options "nosniff"
    X-XSS-Protection "1; mode=block"
    Strict-Transport-Security "max-age=31536000;"
    Referrer-Policy "same-origin"
    Feature-Policy "self"
    Permissions-Policy interest-cohort=()
  }
}

request.abraxis.tv {
  reverse_proxy {{ env "NOMAD_UPSTREAM_ADDR_overseerr" }}
  encode gzip
  header {
    Content-Security-Policy default-src "*"
    X-Frame-Options "DENY"
    X-Content-Type-Options "nosniff"
    X-XSS-Protection "1; mode=block"
    Strict-Transport-Security "max-age=31536000;"
    Referrer-Policy "same-origin"
    Feature-Policy "self"
    Permissions-Policy interest-cohort=()
  }
}

:80, :443 {
  respond "Too much wub. Nothing Left. Sadness."
}
EOF
      }

      resources {
        cpu    = 100
        memory = 300
      }
    }
  }
}
