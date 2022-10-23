resource "nomad_namespace" "storage" {
  name        = "storage"
  description = "CSI storage stuff."
}

resource "nomad_job" "democratic_csi_iscsi_synology_controller" {
  jobspec = file("../jobs/democratic-csi-iscsi-synology-controller.secret.hcl")

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "democratic_csi_iscsi_synology_node" {
  jobspec = file("../jobs/democratic-csi-iscsi-synology-node.secret.hcl")

  hcl2 {
    enabled = true
  }
}
