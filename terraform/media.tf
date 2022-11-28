resource "nomad_namespace" "media" {
  name        = "media"
  description = "Namespace for Plex and Plex related accessories."
}

resource "nomad_volume" "media_media" {
  volume_id             = "media"
  name                  = "media"
  namespace             = "media"
  type                  = "csi"
  external_id           = "media"
  plugin_id             = "org.democratic-csi.nfs"

  context = {
    node_attach_driver = "nfs"
    provisioner_driver = "nfs"
    server             = "192.168.1.21"
    share              = "/volume2/Media"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = [
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
  }
}

resource "nomad_volume" "plex_config" {
  volume_id             = "plex-config"
  name                  = "plex-config"
  namespace             = "media"
  type                  = "csi"
  external_id           = "plex-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.plex-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_volume" "tautulli_config" {
  volume_id             = "tautulli-config"
  name                  = "tautulli-config"
  namespace             = "media"
  type                  = "csi"
  external_id           = "tautulli-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.tautulli-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "plex" {
  jobspec = file("../jobs/plex.hcl")

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "tautulli" {
  jobspec = file("../jobs/tautulli.hcl")

  hcl2 {
    enabled = true
  }
}
