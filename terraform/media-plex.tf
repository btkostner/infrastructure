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

      dnsNames    = ["plex.btkostner.io"]

      issuerRef = {
        name = kubernetes_manifest.letsencrypt_production_cert_issuer.manifest.metadata.name
        kind = "ClusterIssuer"
      }
    }
  }

  depends_on = [kubernetes_manifest.letsencrypt_staging_cert_issuer]
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
      ADVERTISE_IP = "https://plex.btkostner.io"
      TZ = "America/Denver"
    }

    hostNetwork = true

    image = {
      tag = "latest"
    }

    ingress = {
      main = {
        annotations = {
          "kubernetes.io/ingress.class" = "nginx"
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

        enabled = true
        size = "20G"
        storageClass = "nfs-client"
      }

      media = {
        enabled = true
        existingClaim = kubernetes_persistent_volume_claim.media.metadata.0.name
        mountPath = "/media"
      }

      tls = {
        enabled = true
        name    = kubernetes_manifest.plex_production_certificate.manifest.spec.secretName
        mountPath = "/tls"
        type = "secret"
      }
    }

    resources = {
      requests = {
        # Hardware acceleration using an Intel iGPU w/ QuickSync and
        # using intel-gpu-plugin (https://github.com/intel/intel-device-plugins-for-kubernetes)
        # "gpu.intel.com/i915" = 1
        cpu                  = "2"
        memory               = "1024Mi"
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
