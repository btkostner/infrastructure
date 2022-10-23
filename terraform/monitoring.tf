resource "nomad_namespace" "monitoring" {
  name        = "monitoring"
  description = "Prometheus, Grafana, Loki and other monitoring stuff."
}

resource "nomad_job" "alert_manager" {
  jobspec = file("../jobs/alert-manager.hcl")

  hcl2 {
    enabled = true
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
