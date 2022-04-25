resource "kubernetes_namespace" "nfs" {
  metadata {
    name = "nfs-system"
  }
}

resource "helm_release" "nfs_subdir_external_provisioner" {
  name      = "nfs-subdir-external-provisioner"
  namespace = kubernetes_namespace.nfs.metadata.0.name

  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  chart      = "nfs-subdir-external-provisioner"
  version    = "4.0.16"

  set {
    name  = "nfs.server"
    value = "192.168.1.21"
  }

  set {
    name  = "nfs.path"
    value = "/volume1/Cluster"
  }

  set {
    name  = "storageClass.defaultClass"
    value = true
  }
}
