resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "helm_release" "grafana" {
  name      = "grafana"
  namespace = kubernetes_namespace.grafana.metadata.0.name

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.5.1"

  set {
    name  = "grafana.enabled"
    value = true
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = "nfs-client"
  }

  set {
    name  = "prometheus.enabled"
    value = true
  }

  set {
    name  = "prometheus.alertmanager.persistentVolume.enabled"
    value = true
  }

  set {
    name  = "prometheus.alertmanager.persistentVolume.storageClass"
    value = "nfs-client"
  }

  set {
    name  = "prometheus.alertmanager.persistentVolume.size"
    value = "20Gi"
  }

  set {
    name  = "prometheus.server.persistentVolume.enabled"
    value = true
  }

  set {
    name  = "prometheus.server.persistentVolume.storageClass"
    value = "nfs-client"
  }

  set {
    name  = "prometheus.server.persistentVolume.size"
    value = "20Gi"
  }

  set {
    name  = "loki.persistence.enabled"
    value = true
  }

  set {
    name  = "loki.persistence.storageClassName"
    value = "nfs-client"
  }

  set {
    name  = "loki.persistence.size"
    value = "20Gi"
  }

  lifecycle {
    ignore_changes = [metadata, status]
  }
}

resource "kubernetes_service" "grafana_lb" {
  metadata {
    name      = "grafana-lb"
    namespace = kubernetes_namespace.grafana.metadata.0.name
  }

  spec {
    load_balancer_ip = "192.168.1.120"
    port {
      port        = 80
      target_port = 3000
    }
    selector = {
      "app.kubernetes.io/name" = helm_release.grafana.metadata.0.name
    }
    session_affinity = "ClientIP"
    type             = "LoadBalancer"
  }
}
