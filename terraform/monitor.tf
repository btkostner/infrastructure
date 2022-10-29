resource "nomad_namespace" "monitor" {
  name        = "monitor"
  description = "Prometheus, Grafana, Loki and other monitoring stuff."
}

resource "nomad_volume" "prometheus_data" {
  volume_id             = "prometheus-data"
  name                  = "prometheus-data"
  namespace             = "monitor"
  type                  = "csi"
  external_id           = "prometheus-data"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.prometheus-data"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_volume" "loki_data" {
  volume_id             = "loki-data"
  name                  = "loki-data"
  namespace             = "monitor"
  type                  = "csi"
  external_id           = "loki-data"
  plugin_id             = "org.democratic-csi.iscsi-synology"

  context = {
    node_attach_driver = "iscsi"
    provisioner_driver = "synology-iscsi"
    portals = "192.168.1.21"
    iqn = "iqn.2000-01.com.synology:Behemoth.loki-data"
    lun = "1"
  }

  capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "prometheus" {
  jobspec = file("../jobs/prometheus.hcl")

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "loki" {
  jobspec = file("../jobs/loki.hcl")

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "grafana" {
  jobspec = file("../jobs/grafana.hcl")

  hcl2 {
    enabled = true
  }
}
