resource "nomad_namespace" "storage" {
  name        = "storage"
  description = "CSI storage stuff."
}

resource "nomad_job" "democratic_controller" {
  jobspec = <<EOT
job "democratic-csi-iscsi-controller" {
  namespace   = "storage"
  datacenters = ["cluster"]

  group "controller" {
    task "plugin" {
      driver = "podman"

      config {
        image = "docker.io/democraticcsi/democratic-csi:latest"

        args = [
          "--csi-version=1.5.0",
          "--csi-name=org.democratic-csi.iscsi",
          "--driver-config-file=$${NOMAD_TASK_DIR}/driver-config-file.yaml",
          "--log-level=info",
          "--csi-mode=controller",
          "--server-socket=/csi/csi.sock",
        ]
      }

      template {
        destination = "$${NOMAD_TASK_DIR}/driver-config-file.yaml"

        data = <<EOH
driver: synology-iscsi
httpConnection:
  protocol: http
  host: 102.168.1.21
  port: 5000
  username: ""
  password: ""
  allowInsecure: true
  session: "democratic-csi"
  serialize: true

synology:
  volume: /volume1

iscsi:
  targetPortal: "192.168.1.21"
  interface: ""
  baseiqn: "iqn.2000-01.com.synology:Behemoth."
  namePrefix: "cluster-"
  nameSuffix: ""

  lunTemplate:
    type: "BLUN"
    dev_attribs:
    - dev_attrib: emulate_tpws
      enable: 1
    - dev_attrib: emulate_caw
      enable: 1
    - dev_attrib: emulate_3pc
      enable: 1
    - dev_attrib: emulate_tpu
      enable: 1
    - dev_attrib: can_snapshot
      enable: 1

  lunSnapshotTemplate:
    is_locked: true
    is_app_consistent: true

  targetTemplate:
    auth_type: 0
    max_sessions: 0
EOH
      }

      csi_plugin {
        id        = "org.democratic-csi.iscsi"
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
EOT

  hcl2 {
    enabled = true
  }
}
