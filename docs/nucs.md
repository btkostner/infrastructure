# docs/nucs

The Kubernetes server runs on bare metal Intel nucs set up in my server rack. This provides a quiet, highly scalable, and easy to maintain cluster.

## Setup

### Ubuntu Server USB

The first thing you'll need for this is a bootable USB with Ubuntu Server on it. I recommend an LTS version for added support and stability, but any version of Ubuntu Server within the last 4 years should work without an issue.

First, download Ubuntu Server from the Canonical website here: https://ubuntu.com/download/server

Second, `dd` it to a free USB. You can identify what USB you have with `lsblk`.

Once you identify where your drive is, just do this command:

```sh
sudo dd if=<iso path> of=<usb path> bs=1M status=progress
```

### Installation

Now, take the newly created USB and pop it in the USB to the new nuc, plug in a keyboard, and start it up.

On boot up, one of the first screens you should hit is the network setup screen. At this point, you should load up the Unifi interface, find the device and give it a fixed IP address. Once this is applied, you can remove the network cable for a couple of seconds, plug it back in, and you should see the correct IP address set under DHCPv4.

When you get to the storage configuration, you can select the entire disk, and ensure the "Set up this disk as an LVM group" is **not** checked.

Then you should arrive at the "Profile setup" screen. Enter these details:
- Your name: `Blake Kostner`
- Your server's name: `nuc-<number>-zone-<zone>` IE: `nuc-1-zone-a`
- Pick a username: `btkostner`
- Choose a password: you know what ;)

After that is the "SSH Setup". Ensure you have the "Install OpenSSH" is checked but nothing else.

And lastly is the "Featured Server Snaps" page. Click nothing.

### Provisioning

Once you have finished installation and rebooted, you should be able to access the server. Double check this by running:

```sh
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no btkostner@<server address>
```

Once you ensure you can ssh into the server, you'll want to add the IP address to the ansible inventory file. This is located in `ansible/inventories/production/hosts`. Add it to the `common` block along with the hostname. After it's added to the inventory, you can run this ansible command to provision it:

```sh
ansible-playbook -u btkostner --ask-pass --ask-become-pass -l <ip address> playbooks/site.yml
```

This will set up the nuc with all of the needed dependencies, and add it to the kubernetes cluster!
