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
    value = "192.168.1.100"
  }

  lifecycle {
    ignore_changes = [metadata, status]
  }
}

resource "kubernetes_secret" "ddns" {
  metadata {
    name      = "ddns-config"
    namespace = kubernetes_namespace.nginx.metadata.0.name
  }

  data = {
    "ddclient.conf" = <<EOF
daemon=600
syslog=yes
verbose=yes
ssl=yes
use=web, web=checkip.dyndns.com/, web-skip='Current IP Address: '

protocol=cloudflare, \
zone=abraxis.tv, \
login=btkostner@gmail.com, \
password=${var.cloudflare_api_key} \
abraxis.tv, request.abraxis.tv
EOF
  }
}

resource "kubernetes_deployment" "ddclient" {
  metadata {
    name      = "ddclient"
    namespace = kubernetes_namespace.nginx.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/instance" = "ddclient"
        "app.kubernetes.io/name"     = "ddclient"
      }
    }

    template {
      metadata {
        name      = "ddclient"
        namespace = kubernetes_namespace.nginx.metadata.0.name
        labels = {
          "app.kubernetes.io/instance" = "ddclient"
          "app.kubernetes.io/name"     = "ddclient"
        }
      }

      spec {
        container {
          name  = "ddclient"
          image = "linuxserver/ddclient"

          env {
            name  = "TZ"
            value = "America/Denver"
          }

          volume_mount {
            name       = "config"
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
