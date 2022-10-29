resource "nomad_namespace" "download" {
  name        = "download"
  description = "Namespace for applications that download things."
}

resource "nomad_volume" "media" {
  volume_id             = "media"
  name                  = "media"
  namespace             = "download"
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

resource "nomad_volume" "prowlarr_config" {
  volume_id             = "prowlarr-config"
  name                  = "prowlarr-config"
  namespace             = "download"
  type                  = "csi"
  external_id           = "prowlarr-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.prowlarr-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "prowlarr" {
  jobspec = file("../jobs/prowlarr.hcl")

  hcl2 {
    enabled = true
  }
}
