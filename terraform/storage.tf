resource "nomad_namespace" "storage" {
  name        = "storage"
  description = "CSI storage stuff."
}

resource "nomad_job" "democratic_csi_iscsi_synology_controller" {
  jobspec = file("../jobs/democratic-csi-iscsi-synology-controller.hcl")

  hcl2 {
    enabled = true
  }

  depends_on = [nomad_namespace.storage]
}

resource "nomad_job" "democratic_csi_iscsi_synology_node" {
  jobspec = file("../jobs/democratic-csi-iscsi-synology-node.hcl")

  hcl2 {
    enabled = true
  }

  depends_on = [nomad_namespace.storage, nomad_job.democratic_csi_iscsi_synology_controller]
}

resource "nomad_job" "democratic_csi_nfs_controller" {
  jobspec = file("../jobs/democratic-csi-nfs-controller.hcl")

  hcl2 {
    enabled = true
  }

  depends_on = [nomad_namespace.storage]
}

resource "nomad_job" "democratic_csi_nfs_node" {
  jobspec = file("../jobs/democratic-csi-nfs-node.hcl")

  hcl2 {
    enabled = true
  }

  depends_on = [nomad_namespace.storage, nomad_job.democratic_csi_nfs_controller]
}
