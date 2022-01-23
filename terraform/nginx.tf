resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "nginx" {
  name      = "nginx"
  namespace = kubernetes_namespace.nginx.metadata.0.name

  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"
  version    = "0.12.0"

  cleanup_on_fail = true
  reset_values    = true

  set {
    name  = "service.loadBalancerIP"
    value = "192.168.1.101"
  }

  lifecycle {
    ignore_changes = [metadata, status]
  }
}

resource "kubernetes_secret" "ddns" {
  metadata {
    name = "ddns-config"
    namespace = kubernetes_namespace.nginx.metadata.0.name
  }

  data = {
    "ddclient.conf" = <<EOF
daemon=600
use=web
web=checkip.dyndns.org
protocol=cloudflare
zone=btkostner.io
ttl=1
login=token
password=${var.cloudflare_api_key}
plex.btkostner.io
EOF
  }
}

resource "kubernetes_cron_job_v1" "ddns" {
  metadata {
    name = "ddns"
    namespace = kubernetes_namespace.nginx.metadata.0.name
  }

  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 5
    schedule                      = "*/10 * * * *"
    starting_deadline_seconds     = 60
    successful_jobs_history_limit = 5

    job_template {
      metadata {
        name = "ddns"
      }

      spec {
        active_deadline_seconds    = 240
        backoff_limit              = 2

        template {
          metadata {
            name = "ddns"
          }

          spec {
            container {
              name    = "ddclient"
              image   = "linuxserver/ddclient"

              env {
                name  = "TZ"
                value = "America/Denver"
              }

              volume_mount {
                name = "config"
                mount_path = "/config"
              }
            }

            volume {
              name = "config"
              secret {
                secret_name = kubernetes_secret.ddns.metadata.0.name
              }
            }
          }
        }
      }
    }
  }
}
