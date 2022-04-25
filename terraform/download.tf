resource "kubernetes_namespace" "download" {
  metadata {
    name = "download"
  }
}

resource "kubernetes_persistent_volume" "download_media" {
  metadata {
    name = "download-media"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    capacity = {
      storage = "20T"
    }
    mount_options = [
      "rw",
      "relatime",
      "vers=4.1",
      "rsize=32768",
      "wsize=32768",
      "namlen=255",
      "proto=tcp",
      "timeo=14",
      "retrans=2",
      "sec=sys",
      "local_lock=none"
    ]
    storage_class_name = "nfs-client"

    persistent_volume_source {
      nfs {
        path   = "/volume2/Media"
        server = "192.168.1.21"
      }
    }
  }
}

resource "kubernetes_persistent_volume" "download_pool" {
  metadata {
    name = "download-pool"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    capacity = {
      storage = "500G"
    }
    mount_options = [
      "rw",
      "relatime",
      "vers=4.1",
      "rsize=32768",
      "wsize=32768",
      "namlen=255",
      "proto=tcp",
      "timeo=14",
      "retrans=2",
      "sec=sys",
      "local_lock=none"
    ]
    storage_class_name = "nfs-client"

    persistent_volume_source {
      nfs {
        path   = "/volume1/Cluster/download-pool"
        server = "192.168.1.21"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "download_media" {
  metadata {
    name      = "media"
    namespace = kubernetes_namespace.download.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "20T"
      }
    }
    volume_name = kubernetes_persistent_volume.download_media.metadata.0.name
  }
}

resource "kubernetes_persistent_volume_claim" "download_pool" {
  metadata {
    name      = "pool"
    namespace = kubernetes_namespace.download.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "500G"
      }
    }
    volume_name = kubernetes_persistent_volume.download_pool.metadata.0.name
  }
}
