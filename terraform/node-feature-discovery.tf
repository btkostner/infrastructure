resource "kubernetes_namespace" "node_feature_discovery" {
  metadata {
    name = "node-feature-discovery"
  }
}

resource "helm_release" "node_feature_discovery" {
  name      = "node-feature-discovery"
  namespace = kubernetes_namespace.node_feature_discovery.metadata.0.name

  repository = "https://kubernetes-sigs.github.io/node-feature-discovery/charts"
  chart      = "node-feature-discovery"
  version    = "0.11.0"

  cleanup_on_fail = true
  reset_values    = true

  values = [jsonencode({
    master = {
      extraLabelNs = "gpu.intel.com"
    }
  })]

  lifecycle {
    ignore_changes = [metadata, status]
  }
}
