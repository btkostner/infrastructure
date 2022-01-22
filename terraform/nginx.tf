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
