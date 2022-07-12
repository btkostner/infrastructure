resource "kubernetes_storage_class" "iscsi" {
  metadata {
    name = "iscsi"
  }

  storage_provisioner = "kubernetes.io/iscsi"
  reclaim_policy      = "Retain"
  mount_options       = [
    "rw",
    "relatime",
    "stripe=256"
  ]
}
