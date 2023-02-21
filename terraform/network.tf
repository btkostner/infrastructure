resource "nomad_namespace" "network" {
  name        = "network"
  description = "Namespace for networking ingress and egress things."
}

resource "nomad_volume" "caddy_internal_tailscale_data" {
  volume_id             = "caddy-internal-tailscale-data"
  name                  = "caddy-internal-tailscale-data"
  namespace             = "network"
  type                  = "csi"
  external_id           = "caddy-internal-tailscale-data"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.caddy-internal-tailscale-data"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }

  depends_on = [nomad_namespace.network, nomad_job.democratic_csi_iscsi_synology_node]
}

resource "nomad_job" "caddy_external" {
  jobspec = file("../jobs/caddy-external.hcl")

  hcl2 {
    enabled = true
  }

  depends_on = [nomad_namespace.network]
}

resource "nomad_job" "caddy_internal" {
  jobspec = file("../jobs/caddy-internal.hcl")

  hcl2 {
    enabled = true
  }

  depends_on = [nomad_namespace.network, nomad_job.democratic_csi_iscsi_synology_node]
}

resource "nomad_job" "ddns-abraxis" {
  jobspec = file("../jobs/ddns-abraxis.hcl")

  hcl2 {
    enabled = true
  }

  depends_on = [nomad_namespace.network]
}

resource "nomad_job" "ddns-lizandblake" {
  jobspec = file("../jobs/ddns-lizandblake.hcl")

  hcl2 {
    enabled = true
  }

  depends_on = [nomad_namespace.network]
}
