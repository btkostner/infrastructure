resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb-system"
  }
}

resource "helm_release" "metallb" {
  name      = "metallb"
  namespace = kubernetes_namespace.metallb.metadata.0.name

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "bitnami/metallb"
  version    = "2.6.1"
}

resource "kubernetes_config_map" "metallb_config" {
  metadata {
    name      = "config"
    namespace = kubernetes_namespace.metallb.metadata.0.name
  }

  data = {
    config = yamlencode({
      address-pools = [
        {
          name      = "cheap"
          protocol  = "layer2"
          addresses = ["192.168.3.100-192.168.3.254"]
        },
        {
          name = "expensive"
          protocol = "layer2"
          addresses = ["192.168.3.2-192.168.3.99"]
        }
      ]
    })
  }
}
