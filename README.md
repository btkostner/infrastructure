<h1 align="center">
  Infrastructure
</h1>

<p align="center">
  <img height="200" src="./docs/images/talos.svg" alt="Talos">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img height="200" src="./docs/images/kubernetes.svg" alt="Kubernetes">
</p>

This repository includes all of the configuration and documentation for my home lab cluster.

This was taken and customised from [https://github.com/btkostner/infrastructure](https://infrastructure.btkostner.io/)


## Features

- [Talos Linux](https://www.talos.dev) cluster with NVMe as a boot drive and SSD for data
- [Talos Backup](https://github.com/siderolabs/talos-backup) a dead simple backup tool for Talos Linux-based Kubernetes clusters to push to s3
- [Cilium CNI](https://cilium.io/) Container Network Interface -- Chosen (and switched to) because of its high performance and implementation of L7 network policies. Also provides l2 annnouncements, removing the need for metallb.
- [Argo CD](https://argo-cd.readthedocs.io/en/stable/) for cluster bootstrapping
- **deprecated** [Metallb](https://metallb.io/) for L2 loadbalancing (note I intend to deprecate this in time with the inbuilt L2 loadbalancing of the Cilium CNI
- [Gateway API](https://gateway-api.sigs.k8s.io/) via Cilium for ingress: a single `external-gateway` (in `kube-system`) with a wildcard certificate, and an `HTTPRoute` per app. Plain HTTP is redirected to HTTPS by one shared route.
- **removed** [ingress-nginx](https://github.com/kubernetes/ingress-nginx) (retired upstream, archived 2026-03); every app moved to the Gateway API and the controller was removed in November 2026
- [cert-manager](https://cert-manager.io/) to manage certificates, in particular provision valid HTTPS certificates.
- [external-secrets](https://external-secrets.io/latest/) and [bitwarden-sdk-server](https://github.com/external-secrets/bitwarden-sdk-server)to connect to the cloud instance of Bitwarden Secrets Manager for secrets storage and dynamic sync into the cluster. Only needs to be unlocked once at the start. Relies on cert-manager to create a self-signed certificate in order to allow the bitwarden-sdk-server to function.
- [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) to allow for basic storage provisioning. This has been setup to provision the same storage if deployed twice. This effectively means deploying the same cluster twice (say you lose the first one) all your applications will stay identical / not lose their state.
- [external-dns](https://github.com/kubernetes-sigs/external-dns) Used to update DNS records in my Synology SRM DNS Server (via rfc2136) to keep DNS records in sync with l2 loadbalancers dynamically provisioned. With metallb + ingress, this was less important as you could more easily share a single loadbalanced IP across many services. But with Cilium l2 + gateway-api, they really don't seem to be setup to share a single IP, and instead are provisioning a new IP per gateway. Therefore, external-dns helps keep everything in sync.
= [keycloak](https://www.keycloak.org/) identity provider to cluster applications that want it, currently linked up to Google as an identity provider for me.`  Haven't explored making this any sort of cluster-level identity provider.
- [Talos NVIDIA GPU Extensions](https://www.talos.dev/v1.9/talos-guides/configuration/nvidia-gpu/) Kernel modules and everything required to run GPU workloads within the cluster
- [NVIDIA k8s-device-plugin](https://github.com/NVIDIA/k8s-device-plugin) - advertises GPU stats on nodes that have GPUs
  - [gpu-feature-discovery](https://github.com/NVIDIA/k8s-device-plugin?tab=readme-ov-file#deploying-with-gpu-feature-discovery-for-automatic-node-labels) Installed automatically with the NVIDIA k8s-device-plugin, advertises basic k8s node features.
  - [node-feature-discovery](https://github.com/kubernetes-sigs/node-feature-discovery) Installed automatically with the NVIDIA k8s-device-plugin, advertises basic k8s node features.
- [KubeVirt](https://kubevirt.io/) - Ability to run VMs ontop of K8s in Talos (special guide [here](https://github.com/NVIDIA/k8s-device-plugin)).  Steps included: 
  - [local-path-provisioner](https://www.talos.dev/v1.9/kubernetes-guides/configuration/local-storage/)
  - A NFS-CSI - I believe the nfs-subdir-external-provisioner above is sufficient for this, skipped

## High Level Concepts

Deploys main components: 
 - everything in the `provision` sets up the TalosOS installation, TalosOS cluster, and empty kubenetes cluster
 - `cluster\core` and `cluster\crds` sets up all the core kubernetes services I chose to provide a functioning cluster (certificate management, ingress, secrets, CNI, CICD, etc)
 - `cluster\apps` an argocd App of Apps pattern deployment, deploying applications using the services above
 - (hidden) a private repo deploying other apps.

Basic steps would be:
1. Tweak cluster configuration. Suggest reviewing the `provision` directory for all the cluster defaults and customise as you require.
1. Setup Talos configuration and form a Talos Cluster
1. Bootstrap k8s cluster (disabling default CNI)
1. Add BitWarden Secrets Manager key to k8s cluster
1. Deploy once the `core` Kustomize manifests.  Deploys the core services the cluster requires (including replacement CNI), and Argo-cd
    1. Install [Cilium](https://cilium.io) as CNI for sidecar-less networking and L2-L7 policy enforcement
1. Argo-cd then automatically deploys the following app deployments
    1. The same `core` manifests from above, ensuring compliance and declarative git-ops from then on of the core cluster services.
    1. "root" found in the `./cluster/apps/root` folder of this repo, and sets up some example apps and shows how an app of apps can be deployed in Argocd
    1. "root-private" points at a personal repo that is setup the same as "root" 
1. NOTE - because there are some operators installed within this cluster, Argo-cd has been told what to ignore, otherwise the Operators and Argo have a fight over state.

Disabled from the original repository I forked from
- [Rook Ceph](https://rook.io) for stateful replicated storage for all nodes
- [Velero](https://velero.io) for offsite cluster backup

## Management Client

``` bash
# either install using brew -- downside is that TalosOS do not provide historical versions in their Brew packages for some reason, making it unusable when needing to upgrade as you have to have the older talosctl to upgrade
brew install siderolabs/tap/talosctl

# Or my preferred method (changing version number as required): 
cd ~
#curl -LO https://github.com/siderolabs/talos/releases/download/v1.12.7/talosctl-linux-amd64
curl -LO https://github.com/siderolabs/talos/releases/download/v1.13.0/talosctl-linux-amd64
chmod +x talosctl-linux-amd64
sudo mv talosctl-linux-amd64 /usr/local/bin/talosctl
talosctl version
```

see wsl.md for details on how to install the management client within Windows Subsystem for Linux (Ubuntu 24.04)

## DNS
talos-gpu.rockyroad.rocks (TalosOS requires a fixed DNS record to point to it. There are other options, but this was the easiest for me).  The TalosOS API will be hosted at: https://talos-gpu.rockyroad.rocks:6443

## Steps to Form Cluster and Bootstrap Argo-CD 

Boot the control pane machine with the specific Talos Linux image (i.e. via USB boot disk).  You get this image from: [https://factory.talos.dev](https://factory.talos.dev), I record both the steps I use and the resultant URL/hash for the image into this file: [provision\talos\patches\image.yaml](provision\talos\patches\image.yaml). This is important for two reasons: (1) You'll want to remember what options you chose later when you want to upgrade TalosOS, and (2) this boot disk isn't the image that is installed, it is used to bootstrap the hardware into a read only TalosOS, which you then point push configuration to which will download a new version (in my case, the version you specify in that `image.yaml` file)

Choosing the right packages can be a bit fiddly to make sure you select the right packages to support your hardware as TalosOS is a super light weight distro and includes almost nothing unless you specify it. Without the right packages, TalosOS doesn't work properly. 

Make sure the hardware/server has a statically defined IP address (best with a static DHCP reservation)

``` bash
set +o history
export BWS_ACCESS_TOKEN=<MACHINE_TOKEN>
set -o history

cd ~
git clone https://github.com/ugoogalizer/kubernetes-talos.git
cd ~/kubernetes-talos/provision/talos
./generate.sh

# Now apply the patched configuration file (first time):
talosctl apply-config --insecure -n 10.20.8.62 --file ./controlplane.yaml 

# To apply the patched configuration file (all subsequent times, to update configuration):
talosctl apply-config -e 10.20.8.62 -n 10.20.8.62 --file ./controlplane.yaml --talosconfig=./talosconfig
# To apply the patched configuration file and reboot (all subsequent times, to update configuration):
talosctl apply-config -e 10.20.8.62 -n 10.20.8.62 --file ./controlplane.yaml --talosconfig=./talosconfig --mode=reboot

# Bootstrap the cluster - DO THIS ONLY ONCE
talosctl bootstrap -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig

# Download the kubeconfig (merging in to defaults)
talosctl kubeconfig ~/.kube/config -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig

# Configure BitWarden Token to allow sm-operator to pull from cloud secrets
kubectl create namespace external-secrets
kubectl create secret generic bitwarden-access-token -n external-secrets --from-literal=token="$BWS_ACCESS_TOKEN"
# kubectl get secret bitwarden-access-token -o jsonpath="{.data.token}" -n external-secrets | base64 -d

# Install Core resources
cd ~/kubernetes-talos/provision/core
./install.sh
# NOTE - sometimes cert-manager isn't online fast enough to apply the lot, try again after a few minutes if errors occur.

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

# Optional steps
Create keys for talos-backup

``` bash
# sudo apt install age -y # https://github.com/FiloSottile/age#installation
age-keygen

```

# Adding Worker Node/s

Boot the machine with the specific Talos Linux image (i.e. via USB boot disk).

Make sure it has a statically defined IP address (best with a static DHCP reservation)

On the management client:
``` bash
cd ~/kubernetes-talos/provision/talos
git pull
# if not already setup on this client, run: 
  # set +o history
  # export BWS_ACCESS_TOKEN=<MACHINE_TOKEN>
  # set -o history
  # ./generate.sh

# some steps to explore the node before configuration is applied: 
talosctl get disk  --insecure  -n 10.20.8.61  # Get disks topology, useful to confirm you're installing to the right disk

# Add node to the cluster:
talosctl apply-config --insecure -n 10.20.8.61 --file ./worker.yaml --talosconfig=./talosconfig # for a generic worker
talosctl apply-config --insecure -n 10.20.8.61 --file ./worker-largeworkload.yaml --talosconfig=./talosconfig # for a worker reserved for large workloads

# Alternatively, if config already applied and you need to update
talosctl apply-config -e 10.20.8.62 -n 10.20.8.61 --file ./worker-largeworkload.yaml --talosconfig=./talosconfig --mode=reboot

# To apply a taint and label: 

kubectl taint nodes maurice workload=LargeWorkload:NoSchedule
kubectl label nodes maurice workload=LargeWorkload
```

# Setting up a new management node in linux (Bazzite) (to remote in with)

``` bash
# install bitwarden secrets manager (bws)
curl https://bws.bitwarden.com/install | sh

# install kubectl
mkdir ~/.local/bin
curl -LO "https://dl.k8s.io/release/v1.36.6/bin/linux/amd64/kubectl" # match the cluster minor (±1)
cp ./kubectl ~/.local/bin

# install talosctl
brew install siderolabs/tap/talosctl

# install helm

#Check this resolves: 
nslookup talos-gpu.rockyroad.rocks


#Load the bitwarden access token (but not store it in history)
set +o history
export BWS_ACCESS_TOKEN=<MACHINE_TOKEN>
set -o history

cd ~
git clone https://github.com/ugoogalizer/kubernetes-talos.git
cd ~/kubernetes-talos/provision/talos
./generate.sh

#Test it works: 
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get rd

#Now get the kubeconfig: 
talosctl kubeconfig ~/.kube/config -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig


```

# Troubleshooting

If you have issues with argocd, and need to downgrade it / uninstall it, this guide was good to remove the finalizers:  https://phalanx.lsst.io/applications/argocd/upgrade.html#recovering-from-a-botched-upgrade

# Upgrading TalosOS and/or Installing Extensions (effectively the same process, you're replacing the immutable OS image)

If you need to upgrade the Talos Linux cluster, either in version or adding extensions (such as the NVIDIA extensions) you are supposed to do it via API.  I think this is **really stupid**, because the whole point of Talos was to declaratively define it's state in a configuration file.  Running an API command moves your Talos Configuration out of sync with your configuration files.  So in my case, I tried to ensure my process ensured they stayed in sync by: 

1. go to https://factory.talos.dev/ and select what you want (i.e. newer version / new extensions)
    1. Noting that provision\talos\patches\image.yaml is where I'm recording options chosen
    1. Update the provision\talos\patches\image.yaml file to match and commit to git
1. Copy the image link (i.e. factory.talos.dev/metal-installer/a16b5437683037ec314efd168d2bc0521c2c611f99517e47a9bee751108c6cf5:v1.13.0)
1. Patch it into the machine config at machine.install.image.  
1. commit/pull the patch to your control server with talosctl :

``` bash

#NOTE --- CANNOT SKIP A MINOR VERSION, SO CANNOT GO 1.11.x ---> 1.13.x
# TALOSVERSION=v1.11.1
# TALOSVERSION=v1.12.7
# TALOSVERSION=v1.13.0
# TALOSVERSION=v1.13.12  (2026-11, then straight on to v1.14.6; same schematic)
# TALOSVERSION=v1.14.6
# NOTE (1.14+): don't regenerate + apply-config with a 1.14 client without reviewing it first: gen config now
#   adds a SecurityProfileConfig with workloadIsolation: true, which upgrades on their own do not enable.

# Ensure your client version matches the --current-- version (matching target version seems to constantly throw errors): 
cd ~
#curl -LO https://github.com/siderolabs/talos/releases/download/v1.12.7/talosctl-linux-amd64
curl -LO https://github.com/siderolabs/talos/releases/download/v1.13.0/talosctl-linux-amd64
chmod +x talosctl-linux-amd64
sudo mv talosctl-linux-amd64 /usr/local/bin/talosctl
cd ~/kubernetes-talos/provision/talos
talosctl version

### v1.12.7
#Worker first: 
talosctl upgrade -e 10.20.8.62 -n 10.20.8.61 --talosconfig=./talosconfig --image factory.talos.dev/metal-installer/a16b5437683037ec314efd168d2bc0521c2c611f99517e47a9bee751108c6cf5:v1.12.7
# Controller second:
talosctl upgrade -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig --image factory.talos.dev/metal-installer/a16b5437683037ec314efd168d2bc0521c2c611f99517e47a9bee751108c6cf5:v1.12.7
# Note this actually takes a few minutes before it starts to apply for some reason, be patient (I almost sent a follow up command to tell it to reboot, but then it did reboot all on it's own)

### v1.13.0
#Worker first: 
talosctl upgrade -e 10.20.8.62 -n 10.20.8.61 --talosconfig=./talosconfig --image factory.talos.dev/metal-installer/a16b5437683037ec314efd168d2bc0521c2c611f99517e47a9bee751108c6cf5:v1.13.0
# Controller second:
talosctl upgrade -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig --image factory.talos.dev/metal-installer/a16b5437683037ec314efd168d2bc0521c2c611f99517e47a9bee751108c6cf5:v1.13.0
# Note this actually takes a few minutes before it starts to apply for some reason, be patient (I almost sent a follow up command to tell it to reboot, but then it did reboot all on it's own)

# Now Upgrade your client version to match the target version: 
cd ~
curl -LO https://github.com/siderolabs/talos/releases/download/v1.13.0/talosctl-linux-amd64
chmod +x talosctl-linux-amd64
sudo mv talosctl-linux-amd64 /usr/local/bin/talosctl
talosctl version

# # Upgrade the configuration file (which seems meaningless)
cd ~/kubernetes-talos/provision/talos
git pull
rm talosconfig # the config file doesn't generate if this still exists
./generate.sh
talosctl apply-config -e 10.20.8.62 -n 10.20.8.62 --file ./controlplane.yaml --talosconfig=./talosconfig

```

# View GPU Workload and stats

``` bash
kubectl create ns temp
kubectl run \
  nvidia-test \
  --restart=Never \
  -ti --rm \
  --namespace temp \
  --image nvcr.io/nvidia/cuda:12.5.0-base-ubuntu22.04 \
  --overrides '{"spec": {"runtimeClassName": "nvidia"}}' \
  nvidia-smi

# kubectl delete ns temp

```

# Useful Talos Commands

``` bash
cd ~/kubernetes-talos/provision/talos
# Stats about the talos cluster itself (can be done before k8s bootstrapping):
talosctl -e 10.20.8.62 -n 10.20.8.62 containers --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get rd
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get disk
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get namespace
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get extensions
 talosctl -e 10.20.8.62 -n 10.20.8.62 read /proc/cpuinfo --talosconfig=./talosconfig

# Explore the cluster: 
talosctl -e 10.20.8.62 -n 10.20.8.62 health --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 dashboard --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 containers -k --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 get securitystate --talosconfig=./talosconfig

talosctl -e 10.20.8.62 -n 10.20.8.62 service restart kubelet
talosctl -e 10.20.8.62 -n 10.20.8.62 get machineconfig | yq '.machine.network.hostname'

# Explore NVIDIA Setup
talosctl -e 10.20.8.62 -n 10.20.8.62 read /proc/modules --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 get pcidevices -n gpu --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 get pcidevices -n gpu 0000:01:00.0 -o yaml --talosconfig=./talosconfig # Change `0000:01:00.0` with the id of your device from the above command
talosctl -e 10.20.8.62 -n 10.20.8.62 get extensions --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 read /proc/driver/nvidia/version --talosconfig=./talosconfig

# Explore Network
talosctl  -e 10.20.8.62 -n 10.20.8.62 get links  --talosconfig=./talosconfig
talosctl  -e 10.20.8.62 -n 10.20.8.62 get machineconfig -o yaml
talosctl  -e 10.20.8.62 -n 10.20.8.62  exec ip link

# Manually Edit Config
talosctl -e 10.20.8.62  -n 10.20.8.61 edit machineconfig

# Safely power down the Node
talosctl  -e 10.20.8.62 -n 10.20.8.62 shutdown --force # The force skips cordon/drain step, useful in a single node cluster
```

# Basic Containers to test things with: 
``` bash
kubectl create ns temp
kubectl run \
  hello-world \
  --restart=Never \
  -ti --rm \
  --namespace temp \
  --image hello-world:latest 

kubectl run  ubuntu --restart=Never -ti --rm --namespace temp --image ubuntu:latest bash
kubectl run busybox --restart=Never -ti --rm --namespace temp --image busybox:latest sh
kubectl run curl --restart=Never -ti --rm --namespace temp --image curlimages/curl:latest sh
# kubectl delete ns temp
```




# Issues with external-secrets certificate renewals

Turns out this was trust-manager not propagating the CA properly into the secret.  
I think I've fixed the root issue by authorising trust-manager to have access to the right certificate, 
but if not this was the once off fix:
``` bash
#get info on current secret
kubectl -n external-secrets get secret bitwarden-tls-certs
kubectl -n external-secrets describe secret bitwarden-tls-certs
#delete secret
kubectl -n external-secrets delete secret bitwarden-tls-certs
#restart trust manager
# kubectl -n cert-manager rollout restart deployment trust-manager # not required
#get info on new secret
kubectl -n external-secrets get secret bitwarden-tls-certs
kubectl -n external-secrets describe secret bitwarden-tls-certs
#restart bitwarden sdk too
kubectl -n external-secrets rollout restart deployment bitwarden-sdk-server
```

