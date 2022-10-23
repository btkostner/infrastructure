resource "nomad_namespace" "download" {
  name        = "download"
  description = "Namespace for applications that download things."
}

resource "nomad_volume" "prowlarr" {
  volume_id             = "prowlarr"
  namespace             = "download"
  name                  = "prowlarr"
  type                  = "csi"
  external_id           = "k8s-csi-pvc-7879ffc2-3f8b-4d7e-9903-4d18ee70f3d7"
  plugin_id             = "org.democratic-csi.iscsi-synology"

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
