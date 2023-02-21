resource "nomad_namespace" "home_assistant" {
  name        = "home-assistant"
  description = "Namespace for Home Assistant and related services."
}

resource "nomad_volume" "home_assistant_config" {
  volume_id             = "home-assistant-config"
  name                  = "home-assistant-config"
  namespace             = "home-assistant"
  type                  = "csi"
  external_id           = "home-assistant-config"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.home-assistant-config"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "home_assistant" {
  jobspec = file("../jobs/home-assistant.hcl")

  hcl2 {
    enabled = true
  }
}
