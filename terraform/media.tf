resource "kubernetes_namespace" "media" {
  metadata {
    name = "media"
  }
}

resource "kubernetes_persistent_volume" "media_plex_config" {
  metadata {
    name = "media-plex-config"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    capacity = {
      storage = "20G"
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
        path   = "/volume1/Cluster/plex-config"
        server = "192.168.1.21"
      }
    }
  }
}

resource "kubernetes_persistent_volume" "media_plex_media" {
  metadata {
    name = "media-plex-media"
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

resource "kubernetes_persistent_volume_claim" "media_plex_config_old" {
  metadata {
    name      = "plex-config-old"
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "20G"
      }
    }
    storage_class_name = "nfs-client"
    volume_name        = kubernetes_persistent_volume.media_plex_config.metadata.0.name
  }
}

resource "kubernetes_persistent_volume_claim" "media_plex_config" {
  metadata {
    name      = "plex-config"
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "60G"
      }
    }
    storage_class_name = "synology-csi-retain"
  }
}

resource "kubernetes_persistent_volume_claim" "media_plex_media" {
  metadata {
    name      = "plex-media"
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "20T"
      }
    }
    storage_class_name = "nfs-client"
    volume_name        = kubernetes_persistent_volume.media_plex_media.metadata.0.name
  }
}
