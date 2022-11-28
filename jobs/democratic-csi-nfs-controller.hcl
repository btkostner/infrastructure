job "democratic-csi-nfs-controller" {
  namespace   = "storage"
  datacenters = ["cluster"]
  type        = "service"

  group "controller" {
    task "controller" {
      driver = "docker"

      config {
        image = "ghcr.io/btkostner/democratic-csi:debug"

        args = [
          "--csi-version=1.5.0",
          "--csi-name=org.democratic-csi.nfs",
          "--driver-config-file=$${NOMAD_TASK_DIR}/driver-config-file.yaml",
          "--log-level=info",
          "--csi-mode=controller",
          "--server-socket=/csi/csi.sock"
        ]

        privileged = true
        ipc_mode = "host"
        network_mode = "host"
      }

      template {
        destination = "$${NOMAD_TASK_DIR}/driver-config-file.yaml"

        data = <<EOH
driver: nfs-client
instance_id:
nfs:
  shareHost: 192.168.1.21
  shareBasePath: "/volume1/Cluster"
  controllerBasePath: "/storage"
  dirPermissionsMode: "0777"
  dirPermissionsUser: root
  dirPermissionsGroup: wheel
  sudo: true
EOH
      }

      csi_plugin {
        id        = "org.democratic-csi.nfs"
        type      = "controller"
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
