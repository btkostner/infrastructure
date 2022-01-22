variable "cloudflare_api_key" {
  description = "API key for cert manager on Cloudflare"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Email address for cert manager authentication on Cloudflare"
  type        = string
  sensitive   = true
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name      = "cert-manager"
  namespace = kubernetes_namespace.cert_manager.metadata.0.name

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.6.1"

  set {
    name  = "installCRDs"
    value = true
  }
}

resource "kubernetes_secret" "cloudflare_api_key" {
  metadata {
    name      = "cloudflare-api-key"
    namespace = kubernetes_namespace.cert_manager.metadata.0.name
  }

  type = "Opaque"

  data = {
    apikey = var.cloudflare_api_key
  }
}

resource "kubernetes_manifest" "letsencrypt_staging_cert_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = "letsencrypt-staging"
    }

    spec = {
      acme = {
        email  = var.cloudflare_email
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-staging-issuer-account-key"
        }
        solvers = [{
          dns01 = {
            cloudflare = {
              email = var.cloudflare_email
              apiTokenSecretRef = {
                name = kubernetes_secret.cloudflare_api_key.metadata.0.name
                key  = "apikey"
              }
            }
          }
          selector = {
            dnsZones = ["btkostner.io"]
          }
        }]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "letsencrypt_production_cert_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = "letsencrypt-production"
    }

    spec = {
      acme = {
        email  = var.cloudflare_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-production-issuer-account-key"
        }
        solvers = [{
          dns01 = {
            cloudflare = {
              email = var.cloudflare_email
              apiTokenSecretRef = {
                name = kubernetes_secret.cloudflare_api_key.metadata.0.name
                key  = "apikey"
              }
            }
          }
          selector = {
            dnsZones = ["btkostner.io"]
          }
        }]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}
