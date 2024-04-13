# Cilium Upgrades

Upgrading Cilium is... painful. Because it runs as the networking back bone it's very easy to do something wrong and completely break your cluster. As always, read the official Cilium upgrade documentation, but this is how I've been upgrading it so far:

1. Run the preflight checks with helm:

```sh
helm --kube-context admin@btkostner install cilium-preflight cilium/cilium --version 1.15.0 --namespace=kube-system --set preflight.enabled=true --set agent=false --set operator.enabled=false
```

This will pull all of the container images for each node to reduce issues.

2. Condon all of the nodes. This will prevent them from trying to upgrade in place and causing a huge cluster wide outage.

3. Apply the upgrade. This should be done via Argo and merging in a helm version upgrade. Make note to ensure the helm values file is updated for the new version.

4. You should see the cilium operator container start up on the cluster. Make sure no errors are present.

5. Start rebooting nodes. I usually start with the head controller node which is `192.168.3.11` on my cluster. You can accomplish a standard reboot with the `talosctl` utility like so:

```sh
talosctl reboot --debug --wait --timeout 30s -n 192.168.3.11
```

> Note, if you run into issues, it's helpful to use the kvm console to see what's going on. You can also force a reboot with `Ctrl+Alt+Del`.

This should reboot the node safely and bring it back into the cluster. Because it's the same host, it will still be condoned on startup. You can uncondone it and check the status of the cilium agent on the node. It should be running and healthy.

6. Continue rebooting all of the other nodes. Same as above, though now that controller node is back up, you should not get any weird dashboard outages or issues.

7. Once all nodes are rebooted, you can uncondone them all and the cluster should be back to normal.
