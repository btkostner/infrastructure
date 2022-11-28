resource "nomad_namespace" "download" {
  name        = "download"
  description = "Namespace for applications that download things."
}

resource "nomad_volume" "download_download" {
  volume_id             = "download"
  name                  = "download"
  namespace             = "download"
  type                  = "csi"
  external_id           = "download"
  plugin_id             = "org.democratic-csi.nfs"

  context = {
    node_attach_driver = "nfs"
    provisioner_driver = "nfs"
    server             = "192.168.1.21"
    share              = "/volume1/Cluster/download-pool"
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

resource "nomad_volume" "download_media" {
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

resource "nomad_volume" "download_music" {
  volume_id             = "music"
  name                  = "music"
  namespace             = "download"
  type                  = "csi"
  external_id           = "music"
  plugin_id             = "org.democratic-csi.nfs"

  context = {
    node_attach_driver = "nfs"
    provisioner_driver = "nfs"
    server             = "192.168.1.21"
    share              = "/volume2/Media/music"
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

resource "nomad_volume" "nzbget_config" {
  volume_id             = "nzbget-config"
  name                  = "nzbget-config"
  namespace             = "download"
  type                  = "csi"
  external_id           = "nzbget-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.nzbget-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
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

resource "nomad_volume" "sonarr_config" {
  volume_id             = "sonarr-config"
  name                  = "sonarr-config"
  namespace             = "download"
  type                  = "csi"
  external_id           = "sonarr-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.sonarr-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_volume" "radarr_config" {
  volume_id             = "radarr-config"
  name                  = "radarr-config"
  namespace             = "download"
  type                  = "csi"
  external_id           = "radarr-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.radarr-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_volume" "bazarr_config" {
  volume_id             = "bazarr-config"
  name                  = "bazarr-config"
  namespace             = "download"
  type                  = "csi"
  external_id           = "bazarr-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.bazarr-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_volume" "lidarr_config" {
  volume_id             = "lidarr-config"
  name                  = "lidarr-config"
  namespace             = "download"
  type                  = "csi"
  external_id           = "lidarr-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.lidarr-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_volume" "overseerr_config" {
  volume_id             = "overseerr-config"
  name                  = "overseerr-config"
  namespace             = "download"
  type                  = "csi"
  external_id           = "overseerr-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.overseerr-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

// Deluge
resource "nomad_volume" "disk_two" {
  volume_id             = "k8s-csi-pvc-3d69bbc6-3783-497f-9aa0-919cb0575322"
  name                  = "k8s-csi-pvc-3d69bbc6-3783-497f-9aa0-919cb0575322"
  namespace             = "download"
  type                  = "csi"
  external_id           = "k8s-csi-pvc-3d69bbc6-3783-497f-9aa0-919cb0575322"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.pvc-3d69bbc6-3783-497f-9aa0-919cb0575322"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

// Bazarr
resource "nomad_volume" "disk_three" {
  volume_id             = "k8s-csi-pvc-29796a5f-ed52-4567-8971-5b4f2f9868af"
  name                  = "k8s-csi-pvc-29796a5f-ed52-4567-8971-5b4f2f9868af"
  namespace             = "download"
  type                  = "csi"
  external_id           = "k8s-csi-pvc-29796a5f-ed52-4567-8971-5b4f2f9868af"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.pvc-29796a5f-ed52-4567-8971-5b4f2f9868af"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

// Lidarr extended
resource "nomad_volume" "disk_four" {
  volume_id             = "k8s-csi-pvc-37130375-d009-4926-8a1c-00e209ef4b06"
  name                  = "k8s-csi-pvc-37130375-d009-4926-8a1c-00e209ef4b06"
  namespace             = "download"
  type                  = "csi"
  external_id           = "k8s-csi-pvc-37130375-d009-4926-8a1c-00e209ef4b06"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.pvc-37130375-d009-4926-8a1c-00e209ef4b06"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "lidarr" {
  jobspec = file("../jobs/lidarr.hcl")

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "nzbget" {
  jobspec = file("../jobs/nzbget.hcl")

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "overseerr" {
  jobspec = file("../jobs/overseerr.hcl")

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "prowlarr" {
  jobspec = file("../jobs/prowlarr.hcl")

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "radarr" {
  jobspec = file("../jobs/radarr.hcl")

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "sonarr" {
  jobspec = file("../jobs/sonarr.hcl")

  hcl2 {
    enabled = true
  }
}
