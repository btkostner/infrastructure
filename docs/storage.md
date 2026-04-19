# Storage

This cluster uses [Rook Ceph](https://rook.io) to provide distributed storage across all nodes. Each Intel NUC contributes its SSD to a shared Ceph cluster, which is then exposed to workloads via Kubernetes StorageClasses. An external Synology NAS provides additional NFS storage for large media files.

## Ceph Cluster

The Ceph cluster is deployed via the `rook-ceph` Helm chart (v1.19.3) in the `rook-ceph` namespace. It uses all available nodes and devices automatically.

| Component | Count | Resources |
| --------- | ----- | --------- |
| Monitors (mon) | 3 | 500m CPU, 512Mi memory |
| Managers (mgr) | 2 | 500m CPU, 512Mi memory |
| OSDs | auto (all devices) | 1000m CPU, 1024Mi memory |

Key features enabled:

- **Dashboard** — accessible via HTTP route for cluster monitoring
- **Monitoring** — Prometheus metrics are exported
- **Disk prediction** — the `diskprediction_local` module is enabled for drive health forecasting
- **PG autoscaler** — automatically tunes placement group counts
- **CSI read affinity** — reads are served from the closest OSD based on topology
- **Discovery daemon** — automatically detects new devices

The Ceph cluster data directory is stored at `/var/lib/rook` on each node.

## Block Pools

Block pools define how data is replicated across the Ceph cluster. Two pools exist with different durability guarantees.

### `block-pool` (Non-Replicated)

| Property | Value |
| -------- | ----- |
| Failure domain | host |
| Replication size | **1** (no redundancy) |
| RBD mirroring | enabled (image mode) |
| RBD stats | enabled |

> **Warning:** This pool has no data redundancy. If a single OSD or node is lost, data in this pool is lost. Use only for data that is easily recreatable or non-critical.

### `safe-block-pool` (Replicated)

| Property | Value |
| -------- | ----- |
| Failure domain | host |
| Replication size | **3** (full redundancy) |
| RBD mirroring | enabled (image mode) |
| RBD stats | enabled |

This pool stores three copies of every block across different hosts, surviving up to two simultaneous host failures.

## Object Store

### `object-store-replicated` (S3-Compatible)

A Ceph Object Store providing S3-compatible storage with the following configuration:

| Component | Failure Domain | Strategy | Details |
| --------- | -------------- | -------- | ------- |
| Metadata pool | host | Replicated | 3 copies |
| Data pool | host | Erasure coded | 2 data + 1 coding chunk |
| Gateway | — | — | 2 instances, port 80 |

Pool preservation is enabled (`preservePoolsOnDelete: true`), so data pools are retained even if the object store resource is deleted.

## Storage Classes

Storage classes are the primary interface for workloads to request storage. The cluster defines three storage classes.

### Block Storage Classes

All block storage classes use the `rook-ceph.rbd.csi.ceph.com` provisioner with ext4 filesystem, `Retain` reclaim policy, `Immediate` volume binding, and volume expansion enabled.

| Storage Class | Pool | Replication | Default |
| ------------- | ---- | ----------- | ------- |
| `ceph-block` | `block-pool` | 1× | ✅ Yes |
| `ceph-block-replicated` | `safe-block-pool` | 3× | No |

### Object Storage Classes

| Storage Class | Object Store | Provisioner |
| ------------- | ------------ | ----------- |
| `ceph-object-replicated` | `safe-object-store` | `rook-ceph.ceph.rook.io/bucket` |

### Choosing a Storage Class

- **`ceph-block`** — Use for non-critical, easily recreatable data where performance matters more than durability (1× replication).
- **`ceph-block-replicated`** — Use for important application data that must survive node failures (3× replication).
- **`ceph-object-replicated`** — Use for S3-compatible object/bucket storage with erasure coding.

## NFS Storage

The Synology NAS provides NFS volumes for large media and download directories. NFS PVCs use the `nfs` storage class with `ReadWriteMany` access mode, allowing multiple pods to mount the same volume simultaneously. These are typically sized at 1Mi as nominal placeholders since the actual storage is managed by the NAS.

## Volume Inventory

### By Namespace

#### `developer`

| PVC Name | Storage Class | Size | Access Mode | Application |
| -------- | ------------- | ---- | ----------- | ----------- |
| `opencode-data` | `ceph-block-replicated` | 50Gi | ReadWriteOnce | OpenCode |

#### `download`

| PVC Name | Storage Class | Size | Access Mode | Application |
| -------- | ------------- | ---- | ----------- | ----------- |
| `lidarr-config` | `ceph-block-replicated` | 20Gi | ReadWriteOnce | Lidarr |
| `lidarr-download` | `nfs` | 1Mi | ReadWriteMany | Lidarr |
| `lidarr-media` | `nfs` | 1Mi | ReadWriteMany | Lidarr |
| `prowlarr-config` | `ceph-block-replicated` | 20Gi | ReadWriteOnce | Prowlarr |
| `radarr-config` | `ceph-block-replicated` | 20Gi | ReadWriteOnce | Radarr |
| `radarr-download` | `nfs` | 1Mi | ReadWriteMany | Radarr |
| `radarr-media` | `nfs` | 1Mi | ReadWriteMany | Radarr |
| `sabnzbd-config` | `ceph-block-replicated` | 20Gi | ReadWriteOnce | SABnzbd |
| `sabnzbd-download` | `nfs` | 1Mi | ReadWriteMany | SABnzbd |
| `seerr-config` | `ceph-block-replicated` | 10Gi | ReadWriteOnce | Seerr |
| `sonarr-config` | `ceph-block-replicated` | 20Gi | ReadWriteOnce | Sonarr |
| `sonarr-download` | `nfs` | 1Mi | ReadWriteMany | Sonarr |
| `sonarr-media` | `nfs` | 1Mi | ReadWriteMany | Sonarr |

#### `home`

| PVC Name | Storage Class | Size | Access Mode | Application |
| -------- | ------------- | ---- | ----------- | ----------- |
| `n8n-config` | `ceph-block-replicated` | 10Gi | ReadWriteOnce | n8n |

#### `media`

| PVC Name | Storage Class | Size | Access Mode | Application |
| -------- | ------------- | ---- | ----------- | ----------- |
| `autoscan-media` | `nfs` | 1Mi | ReadWriteMany | Autoscan |
| `ersatztv-config` | `ceph-block-replicated` | 5Gi | ReadWriteOnce | ErsatzTV |
| `ersatztv-media` | `nfs` | 1Mi | ReadWriteMany | ErsatzTV |
| `plex-config` | `ceph-block-replicated` | 300Gi | ReadWriteOnce | Plex |
| `plex-media` | `nfs` | 1Mi | ReadWriteMany | Plex |
| `tautulli-config` | `ceph-block-replicated` | 20Gi | ReadWriteOnce | Tautulli |

#### `rook-ceph` (via Helm)

| Component | Storage Class | Size | Application |
| --------- | ------------- | ---- | ----------- |
| ClickHouse persistence | `ceph-block-replicated` | 50Gi | SigNoz |

### Summary by Storage Class

| Storage Class | Consumers | Total Ceph Storage |
| ------------- | --------- | ------------------ |
| `ceph-block-replicated` | 12 | **555Gi** |
| `nfs` | 11 | N/A (NAS-managed) |

### Largest Consumers

| Application | PVC | Size |
| ----------- | --- | ---- |
| Plex | `plex-config` | 300Gi |
| OpenCode | `opencode-data` | 50Gi |
| SigNoz | ClickHouse persistence | 50Gi |
| Lidarr | `lidarr-config` | 20Gi |
| Prowlarr | `prowlarr-config` | 20Gi |
| Radarr | `radarr-config` | 20Gi |
| SABnzbd | `sabnzbd-config` | 20Gi |
| Sonarr | `sonarr-config` | 20Gi |
| Tautulli | `tautulli-config` | 20Gi |

## Configuration Reference

All Rook Ceph resources are defined in:

```
cluster/rook-ceph/rook-ceph/
├── kustomization.yaml
├── values.yaml
└── resources/
    ├── ceph-block-pool.yaml
    ├── ceph-block-pool-replicated.yaml
    ├── ceph-cluster.yaml
    ├── ceph-object-store-replicated.yaml
    ├── storage-class-ceph-block.yaml
    ├── storage-class-ceph-block-replicated.yaml
    └── storage-class-ceph-object-replicated.yaml
```

Individual application PVCs are defined alongside their deployments in:

```
cluster/<namespace>/<application>/resources/pvc-*.yaml
```
