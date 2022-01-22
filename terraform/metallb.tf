resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb-system"
  }
}

resource "kubernetes_config_map" "metallb_config" {
  metadata {
    name      = "config"
    namespace = kubernetes_namespace.metallb.metadata.0.name
  }

  data = {
    config = jsonencode({
      address-pools = [{
        name      = "default"
        protocol  = "layer2"
        addresses = ["192.168.1.101-192.168.1.140"]
      }]
    })
  }
}

resource "helm_release" "metallb" {
  name      = "metallb"
  namespace = kubernetes_namespace.metallb.metadata.0.name

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metallb"
  version    = "2.6.1"

  set {
    name  = "existingConfigMap"
    value = kubernetes_config_map.metallb_config.metadata.0.name
  }

  lifecycle {
    ignore_changes = [metadata, status]
  }
}
