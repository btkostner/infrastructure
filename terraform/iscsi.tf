resource "kubernetes_namespace" "synology" {
  metadata {
    name = "synology-csi"
  }
}

/**
  * TODO: This is wrong. Look in the cluster for working configuration
  *
resource "kubernetes_secret" "synology_config" {
  metadata {
    name      = "client-info-secret"
    namespace = kubernetes_namespace.synology.metadata.0.name
  }



  data = {
    config = jsonencode({
      clients = [{
        host     = "192.168.1.21"
        port     = "5000"
        https    = false
        username = ""
        password = ""
      }]
    })
  }
}
*/

/**
resource "kubernetes_service_account" "synology_csi_controller_sa" {
  metadata {
    name      = "csi-controller-sa"
    namespace = kubernetes_namespace.synology.metadata.0.name
  }
}

resource "kubernetes_cluster_role" "synology_csi_controller_role" {
  metadata {
    name = "synology-csi-controller-role"
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims/status"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["csinodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["csi.storage.k8s.io"]
    resources  = ["csinodeinfos"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments", "volumeattachments/status"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshots"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotcontents"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "synology_csi_controller_role" {
  metadata {
    name      = "synology-csi-controller-role"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "csi-controller-sa"
    namespace = kubernetes_namespace.synology.metadata.0.name
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "synology-csi-controller-role"
    api_group = "rbac.authorization.k8s.io"
  }
}
*/
