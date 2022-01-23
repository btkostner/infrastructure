# https://github.com/k8s-at-home/charts/tree/master/charts/stable/plex
resource "kubernetes_manifest" "plex_production_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "plex-production"
      namespace = kubernetes_namespace.media.metadata.0.name
    }

    spec = {
      secretName = "plex-btkostner-io-tls"

      duration    = "2160h0m0s"
      renewBefore = "360h0m0s"

      subject = {
        organizations = ["btkostner.io"]
      }

      dnsNames = ["plex.btkostner.io"]

      issuerRef = {
        name = kubernetes_manifest.letsencrypt_production_cert_issuer.manifest.metadata.name
        kind = "ClusterIssuer"
      }
    }
  }

  depends_on = [kubernetes_manifest.letsencrypt_staging_cert_issuer]
}

resource "kubernetes_daemonset" "intel_gpu" {
  metadata {
    name      = "intel-gpu-plugin"
    namespace = kubernetes_namespace.media.metadata.0.name
    labels = {
      app = "intel-gpu-plugin"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "intel-gpu-plugin"
      }
    }

    template {
      metadata {
        labels = {
          app = "intel-gpu-plugin"
        }
      }

      spec {
        init_container {
          name            = "intel-gpu-initcontainer"
          image           = "intel/intel-gpu-initcontainer:0.23.0"
          image_pull_policy = "IfNotPresent"
          security_context {
            read_only_root_filesystem = true
          }
          volume_mount {
            mount_path = "/etc/kubernetes/node-feature-discovery/source.d/"
            name      = "nfd-source-hooks"
          }
        }

        container {
          name = "intel-gpu-plugin"
          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          image           = "intel/intel-gpu-plugin:0.23.0"
          image_pull_policy = "IfNotPresent"

          security_context {
            read_only_root_filesystem = true
          }

          volume_mount {
            name      = "devfs"
            mount_path = "/dev/dri"
            read_only  = true
          }

          volume_mount {
            name      = "sysfs"
            mount_path = "/sys/class/drm"
            read_only  = true
          }

          volume_mount {
            name      = "kubeletsockets"
            mount_path = "/var/lib/kubelet/device-plugins"
          }
        }

        volume {
          name = "devfs"
          host_path {
            path = "/dev/dri"
          }
        }

        volume {
          name = "sysfs"
          host_path {
            path = "/sys/class/drm"
          }
        }

        volume {
          name = "kubeletsockets"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }

        volume {
          name = "nfd-source-hooks"
          host_path {
            path = "/etc/kubernetes/node-feature-discovery/source.d/"
            type = "DirectoryOrCreate"
          }
        }

        node_selector = {
          "kubernetes.io/arch" = "amd64"
        }
      }
    }
  }
}

resource "helm_release" "plex" {
  name      = "plex"
  namespace = kubernetes_namespace.media.metadata.0.name

  repository = "https://k8s-at-home.com/charts"
  chart      = "plex"
  version    = "6.2.0"

  cleanup_on_fail = true
  reset_values    = true

  values = [jsonencode({
    env = {
      ADVERTISE_IP = "https://plex.btkostner.io:443"
      TZ           = "America/Denver"
    }

    hostNetwork = true

    image = {
      tag = "latest"
    }

    ingress = {
      main = {
        annotations = {
          "kubernetes.io/ingress.class" = "nginx"
          "nginx.org/proxy-buffering" = "false"
          "nginx.org/proxy-connect-timeout" = "1m"
          "nginx.org/proxy-read-timeout" = "5m"
          "nginx.org/proxy-send-timeout" = "5m"
/**
          "nginx.org/server-snippets" = <<EOF
# Borrowed from https://github.com/toomuchio/plex-nginx-reverseproxy
send_timeout 100m;

gzip on;
gzip_vary on;
gzip_min_length 1000;
gzip_proxied any;
gzip_types text/plain text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
gzip_disable "MSIE [1-6]\.";

client_max_body_size 100M;

proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Sec-WebSocket-Extensions $http_sec_websocket_extensions;
proxy_set_header Sec-WebSocket-Key $http_sec_websocket_key;
proxy_set_header Sec-WebSocket-Version $http_sec_websocket_version;

proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "Upgrade";
EOF
*/
        }

        enabled = true

        hosts = [{
          host = "plex.btkostner.io"
          paths = [{
            path = "/"
          }]
        }]

        ingressClassName = "nginx"

        tls = [{
          hosts      = ["plex.btkostner.io"]
          secretName = kubernetes_manifest.plex_production_certificate.manifest.spec.secretName
        }]
      }
    }

    persistence = {
      config = {
        annotations = {
          "nfs.io/storage-path" = "media-plex-config-pvc"
        }

        enabled      = true
        size         = "20G"
        storageClass = "nfs-client"
      }

      media = {
        enabled       = true
        existingClaim = kubernetes_persistent_volume_claim.media.metadata.0.name
        mountPath     = "/media"
      }

      tls = {
        enabled   = true
        name      = kubernetes_manifest.plex_production_certificate.manifest.spec.secretName
        mountPath = "/tls"
        type      = "secret"
      }
    }

    resources = {
      requests = {
        # Hardware acceleration using an Intel iGPU w/ QuickSync and
        # using intel-gpu-plugin (https://github.com/intel/intel-device-plugins-for-kubernetes)
        # "gpu.intel.com/i915" = 1
        cpu    = "2"
        memory = "1024Mi"
      }

      limits = {
        cpu    = "8"
        memory = "6144Mi"
      }
    }
  })]

  lifecycle {
    ignore_changes = [metadata, status]
  }
}

resource "kubernetes_service" "plex_lb" {
  metadata {
    name      = "plex-lb"
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    load_balancer_ip = "192.168.1.110"
    port {
      port        = 32400
      target_port = 32400
    }
    selector = {
      "app.kubernetes.io/name" = helm_release.plex.metadata.0.name
    }
    session_affinity = "ClientIP"
    type = "LoadBalancer"
  }
}
