# https://github.com/k8s-at-home/charts/tree/master/charts/stable/plex
resource "kubernetes_namespace" "media" {
  metadata {
    name = "media"
  }
}

resource "kubernetes_persistent_volume" "media" {
  metadata {
    name = "media"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    capacity = {
      storage = "20T"
    }

    persistent_volume_source {
      nfs {
        path   = "/volume2/Media"
        server = "192.168.1.21"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "media" {
  metadata {
    name      = "media"
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "10T"
      }
    }
    volume_name = kubernetes_persistent_volume.media.metadata.0.name
  }
}
