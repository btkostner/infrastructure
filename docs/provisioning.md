# Provisioning

This page goes over how to setup a whole new cluster. Starting with basic networking setup, Talos configuration generating and applying, and Argo CD bootstrapping.

My home cluster is made up of 4x Intel 11th gen i5 NUCs with 32 GB of ram, an NVMe boot drive, and a 1TB SSD for Ceph. All of the nodes are nearly identical to make things easier, though this isn't a hard requirement. The main reason I chose this configuration is for it's low power usage, small space, and Intel Xe graphics.

I also have a PiKVM setup connected to a TESmart 4K 16 Ports HDMI KVM Switch. This allows easy bios control and booting of images. This makes it infinitely easier to install Talos on a cluster.

## Node Setup

Node setup is mostly ensuring all of the hardware is working and has up to date firmware. This is especially important for my Crucial MX500 SSDs as older versions can randomly disconnect and cause Ceph to go into an unhealthy state.

Once all of the hardware is confirmed working, I set a static IP for the node. This starts at `192.168.3.11` and continue for each node. Talos will set a virtual IP at `192.168.3.10` for the control plane nodes.

One important thing to note is I use `cluster.btkostner.network` to point to my cluster virtual IP of `192.168.3.10`. Yes this is a local address so it will only resolve correctly in my network, but that should be fine.

## Generating Talos Configuration

Talos configuration resides in the `provision/talos/` directory. It includes a folder of configuration patches as well as a `generate.sh` script to run the needed `talosctl` commands.

If you plan to run this for your own cluster, ensure all of the patches in `provision/talos/patches` are relevant to you.

Once you are ready, you can run the `generate.sh` script. This will generate your `controlplane.yaml`, `talosconfig`, and `worker.yaml` files. Ensure you back these files.

## Installing Talos

For installing Talos, I grab the latest Talos ISO from GitHub, upload it to my PiKVM, and boot the node into it. This pulls up the Talos instance in bootstrap status. I then run this command for the node:

```sh
talosctl apply --file ./controlplane.yaml --nodes "192.168.3.11" --insecure
```

This sets up the control node. Then run this command to bootstrap the cluster:

```sh
talosctl bootstrap --nodes "192.168.3.11"
```

This does the initial Kubernetes resource creation and what not. At this point, `192.168.3.10` should point to the control plane node.

At this point, I can run the same `talosctl apply` command for all of the other control nodes. Then I apply the worker configuration with:

```sh
talosctl apply --file ./worker.yaml --nodes "192.168.3.14" --insecure
```

With all of that done, there is now a fresh Kubernetes cluster. Note that because the default CNI is not installed, none of the node networking will work _and_ every Kubernetes node will have a taint on it. They will also reboot every 10 minutes until the Cilium CNI is installed.

Finally I run this command to generate the needed `kubectl` entry:

```sh
talosctl kubeconfig ~/.kube/config --nodes talos.btkostner.network --force
```

## Installing Argo CD

TODO...