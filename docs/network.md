# docs/network

## High Level Overview

Cluster IP range is `192.168.100` to `192.168.200`. Here is a breakdown:

- `192.168.1.100` to `192.168.1.140` is reserved for special IPs:

- `192.168.1.141` to `192.168.1.160` is reserved for Zone A

- `192.168.1.161` to `192.168.1.180` is reserved for Zone B

- `192.168.1.181` to `192.168.1.200` is reserved for Zone C

## Instance Breakdown

- `192.168.1.100` `KeepAlived` VRRP to an available Main server

- `192.168.1.141` `nuc-1-zone-a` Zone A Main server

- `192.168.1.161` `nuc-1-zone-b` Zone B Main server
