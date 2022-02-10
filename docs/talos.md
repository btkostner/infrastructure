# docs/talos

All cluster nodes use Talos

## Tidbits

- Boot into gparted and manually delete all partitions to clear all data
- Untaint main nodes with `kubectl taint node talos-192-168-1-161 node-role.kubernetes.io/master:NoSchedule-`
