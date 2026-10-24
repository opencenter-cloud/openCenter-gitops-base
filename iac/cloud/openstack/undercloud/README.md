# Undercloud

Multi-VLAN trunk-port topology for the OpenStack undercloud control plane and its
worker pools. See `examples/iac/undercloud/main.tf` for a full invocation.

## NVIDIA GPU Nodes

Large NVIDIA BARs are only allocated when the kernel re-balances the PCI bridge
windows, so a GPU node needs `pci=realloc,assign-busses,nocrs` on its kernel
command line before the driver loads. Set `enable_pci_realloc` to have the nodes
apply it during cloud-init:

```yaml
module "undercloud" {
  # ...

  # Master and default worker (size_worker) pools.
  enable_pci_realloc = false

  additional_server_pools_worker = [
    {
      name               = "gpu"
      worker_count       = 2
      flavor_worker      = "gp.0.8.32.gpu"
      node_worker        = "gn"
      image_id           = "<ubuntu24_image_id>"
      enable_pci_realloc = true
    },
  ]
}
```

What happens on a node with the flag set:

1. cloud-init installs `/etc/grub.d/00_pci_realloc`, an idempotent snippet that
   appends the options to `GRUB_CMDLINE_LINUX`. Living in `grub.d` means every
   later `update-grub` — including the ones a kernel or grub package upgrade
   triggers after `/etc/default/grub` was reset — re-applies them.
2. The node probes sysfs for a PCI device with vendor `0x10de`. A node without
   an NVIDIA device stops there and leaves its kernel command line untouched, so
   a pool flagged by mistake cannot misconfigure a CPU-only node.
3. A node with a device runs `update-grub`, `update-initramfs -u`, raises
   `/var/run/reboot-required` for kured, and reboots. Unlike the
   `openstack-nova` module, this module has no general reboot switch, so the
   `power_state` reboot is tied to `enable_pci_realloc` alone.

Unlike `openstack-nova`, this module renders the cloud-config **per instance**, so
only the instances of a pool with the flag enabled carry the grub block; the other
pools' renders stay unchanged.

`openstack_compute_instance_v2` ignores `user_data` changes, so the option never
reaches a running node. It applies to nodes created or replaced after the flag is
set; existing GPU nodes have to be replaced to pick it up.

Verify on a joined node with `cat /proc/cmdline | grep pci=realloc` and confirm
the driver sees the device with `lspci -nn | grep -i nvidia`.

## Validation

`terraform test` in `../lib/user_data-ubuntu/test-render` pins the cloud-config
contract for the shared Ubuntu templates. `tests/test_undercloud_validate.py`
covers the undercloud topology.
