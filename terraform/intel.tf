resource "kubernetes_namespace" "intel_gpu_plugin" {
  metadata {
    name = "intel-gpu-plugin"
  }
}

resource "helm_release" "intel_gpu_plugin" {
  name      = "intel-gpu-plugin"
  namespace = kubernetes_namespace.intel_gpu_plugin.metadata.0.name

  repository = "https://k8s-at-home.com/charts/"
  chart      = "intel-gpu-plugin"
  version    = "4.2.0"

  cleanup_on_fail = true
  reset_values    = true

  values = [jsonencode({
    args = [
      "-shared-dev-num",
      "1",
      "-v",
      "1"
    ]

    image = {
      tag = "0.23.0"
    }
  })]

  lifecycle {
    ignore_changes = [metadata, status]
  }
}
