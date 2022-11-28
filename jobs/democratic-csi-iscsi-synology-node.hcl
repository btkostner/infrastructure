job "democratic-csi-iscsi-synology-node" {
  namespace   = "storage"
  datacenters = ["cluster"]
  type        = "system"

  constraint {
    operator = "distinct_hosts"
    value = true
  }

  group "node" {
    task "node" {
      driver = "docker"

      config {
        image = "ghcr.io/btkostner/democratic-csi:debug"

        args = [
          "--csi-version=1.5.0",
          "--csi-name=org.democratic-csi.iscsi-synology",
          "--driver-config-file=$${NOMAD_TASK_DIR}/driver-config-file.yaml",
          "--log-level=debug",
          "--csi-mode=node",
          "--server-socket=/csi/csi.sock",
        ]

        privileged = true
        ipc_mode = "host"
        network_mode = "host"

        mount {
          type     = "bind"
          target   = "/etc/iscsi"
          source   = "/etc/iscsi"
          readonly = false
        }

        mount {
          type     = "bind"
          target   = "/run/udev"
          source   = "/run/udev"
          readonly = true
        }

        mount {
          type     = "bind"
          target   = "/host"
          source   = "/"
          readonly = false
        }

        mount {
          type     = "bind"
          target   = "/sys"
          source   = "/sys"
          readonly = true
        }
      }

      template {
        destination = "$${NOMAD_TASK_DIR}/driver-config-file.yaml"

        data = <<EOH
driver: synology-iscsi
httpConnection:
  protocol: http
  host: 192.168.1.21
  port: 8080
  username: "{{ key "behemoth/username" }}"
  password: "{{ key "behemoth/password" }}"
  allowInsecure: true
  session: "democratic-csi"
  serialize: true

synology:
  volume: /volume1
  sudo: true

synology-iscsi:
  sudo: true

iscsi:
  targetPortal: "192.168.1.21"
  interface: ""
  baseiqn: "iqn.2000-01.com.synology:Behemoth."
  namePrefix: ""
  nameSuffix: ""
  sudo: true

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
        id        = "org.democratic-csi.iscsi-synology"
        type      = "node"
        mount_dir = "/csi"
        health_timeout = "2m"
      }

      resources {
        cpu    = 128
        memory = 128
      }
    }
  }
}
