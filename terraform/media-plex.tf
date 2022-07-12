resource "random_password" "plex_production_certificate_password" {
  length  = 64
  special = false
}

resource "kubernetes_secret" "plex_production_certificate_password" {
  metadata {
    name      = "plex-certificate-password"
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  type = "Opaque"

  data = {
    password = random_password.plex_production_certificate_password.result
  }
}

resource "kubernetes_manifest" "plex_production_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "plex-production"
      namespace = kubernetes_namespace.media.metadata.0.name
    }

    spec = {
      secretName = "plex-production-tls"

      duration    = "2160h0m0s"
      renewBefore = "360h0m0s"

      subject = {
        organizations = ["btkostner LLC"]
      }

      dnsNames = ["abraxis.tv"]

      issuerRef = {
        name = kubernetes_manifest.letsencrypt_production_cert_issuer.manifest.metadata.name
        kind = "ClusterIssuer"
      }

      keystores = {
        pkcs12 = {
          create = true
          passwordSecretRef = {
            key  = "password"
            name = kubernetes_secret.plex_production_certificate_password.metadata.0.name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.letsencrypt_production_cert_issuer]
}

resource "kubernetes_persistent_volume" "media_plex_config_new" {
  metadata {
    name = "media-plex-config-new"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "5G"
    }
    storage_class_name = "iscsi"
    persistent_volume_source {
      iscsi {
        target_portal = "192.168.1.21:3260"
        iqn = "iqn.2022-05.behemoth:plex-config"
        lun = 0
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "media_plex_config_new" {
  metadata {
    name      = "media-plex-config-new"
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5G"
      }
    }
    storage_class_name = "iscsi"
    volume_name = kubernetes_persistent_volume.media_plex_config_new.metadata.0.name
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
    affinity = {
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [{
            matchExpressions = [{
              key      = "btkostner.io.node-restriction.kubernetes.io/dedicated"
              operator = "In"
              values   = ["plex"]
            }]
          }]
        }
      }
    }

    env = {
      ADVERTISE_IP = "https://abraxis.tv:443"
      TZ           = "America/Denver"
    }

    hostNetwork = true

    image = {
      tag        = "latest"
      pullPolicy = "Always"
    }

    ingress = {
      main = {
        annotations = {
          "kubernetes.io/ingress.class"     = "nginx"
          "nginx.org/proxy-buffering"       = "false"
          "nginx.org/proxy-connect-timeout" = "1m"
          "nginx.org/proxy-read-timeout"    = "5m"
          "nginx.org/proxy-send-timeout"    = "5m"
        }

        enabled = true

        hosts = [{
          host = "abraxis.tv"
          paths = [{
            path = "/"
          }]
        }]

        tls = [{
          hosts      = ["abraxis.tv"]
          secretName = kubernetes_manifest.plex_production_certificate.manifest.spec.secretName
        }]
      }
    }

    persistence = {
      config = {
        enabled       = true
        existingClaim = kubernetes_persistent_volume_claim.media_plex_config.metadata.0.name
      }

      /*
      new = {
        enabled = true
        mountPath = "/new"
        type = "pvc"
        existingClaim = kubernetes_persistent_volume_claim.media_plex_config_new.metadata.0.name
      }
      */

      media = {
        enabled       = true
        existingClaim = kubernetes_persistent_volume_claim.media_plex_media.metadata.0.name
        mountPath     = "/media"
      }

      tls = {
        enabled   = true
        name      = kubernetes_manifest.plex_production_certificate.manifest.spec.secretName
        mountPath = "/tls"
        type      = "secret"
      }
    }

    podSecurityContext = {
      supplementalGroups = [44, 109]
    }

    probes = {
      liveness = {
        enabled = true
        custom  = true
        spec = {
          httpGet = {
            path = "/identity"
            port = "http"
          }
          initialDelaySeconds : 0
          periodSeconds : 10
          timeoutSeconds : 1
          failureThreshold : 3
        }
      }
    }

    resources = {
      requests = {
        "gpu.intel.com/i915" = "1"
        cpu                  = "2"
        memory               = "1024Mi"
      }

      limits = {
        "gpu.intel.com/i915" = "1"
        cpu                  = "8"
        memory               = "12288Mi"
      }
    }

    tolerations = [{
      key      = "dedicated"
      operator = "Equal"
      value    = "plex"
      effect   = "PreferNoSchedule"
    }]
  })]

  lifecycle {
    ignore_changes = [metadata]
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
    type             = "LoadBalancer"
  }
}
