# Undercloud Deployment Guide

This guide explains the undercloud-specific configuration in `main.tf` for deploying Kubernetes clusters on the Rackspace undercloud (multi-VLAN trunk-port topology).

## Network Topology Overview

The undercloud uses a trunk-port model where each server gets a single physical NIC carrying multiple VLANs:

```
                          ┌─────────────────────────────────┐
                          │         Physical Server          │
                          │                                  │
  Upstream Switch ────────┤  eno3np0 (trunk parent, native)  │
   (VLAN trunk)           │    ├── mgmt.109 (VLAN 109)      │  ← Management / Kube-VIP / Calico
                          │    └── metal.105 (VLAN 105)     │  ← MetalLB public IPs
                          │                                  │
                          │  hostnet: 10.2.128.0/24          │  ← Native/untagged, DHCP, default route
                          └─────────────────────────────────┘
```

- **Hostnet** — Native (untagged) network on the trunk parent. Provides DHCP, default route, and outbound NAT.
- **Mgmt VLAN** — Tagged VLAN for Kubernetes API access (kube-vip), Calico node-to-node, and SSH.
- **MetalLB VLAN(s)** — Tagged VLAN(s) for public-facing LoadBalancer IPs. No IPs assigned by OpenStack; MetalLB manages them via L2 advertisement.

## Undercloud-Specific Settings

These settings come after the standard cluster/server sizing in `main.tf`:

### `hostnet_cidr`

```hcl
hostnet_cidr = "10.2.128.0/24"
```

The CIDR for the native (untagged) host network. This is the network the trunk parent interface gets its IP from via DHCP. It provides the node's default route and outbound NAT to the internet via an OVN router connected to PUBLICNET.

### `mgmt_vlan_id`

```hcl
mgmt_vlan_id = 109
```

VLAN ID for the management network. This creates a tagged sub-interface (`mgmt.<id>`) on each node. Used for:
- **Kube-VIP** — The HA Kubernetes API floating IP lives here
- **Calico node mesh** — Calico's `nodeAddressAutodetection` uses this interface
- **SSH access** — Nodes are accessed via mgmt IPs (through a ProxyCommand jump)

The mgmt subnet is allocated dynamically from the `mgmt_subnet_pool` (see below). An SVI router provides L3 reachability from the corporate network.

### `mgmt_subnet_pool`

```hcl
mgmt_subnet_pool = "public-tendot-ip4"
```

The OpenStack subnet pool name to allocate the mgmt subnet from. On the undercloud, this is typically `public-tendot-ip4` which hands out routable 10.x.x.x/26 blocks. The allocation happens automatically during Terraform apply.

### `kube_vip_address`

```hcl
kube_vip_address = ""
```

The static IP for kube-vip (Kubernetes API HA VIP). Leave empty to let Terraform allocate one from the mgmt subnet. If you need a specific IP (e.g., for DNS pre-registration), set it here. This IP must be within the mgmt subnet range.

When set, it's added to `allowed_address_pairs` on all control plane mgmt ports so that kube-vip can float the IP between masters.

### `disable_bastion`

```hcl
disable_bastion = true
```

Whether to skip creating a bastion/jump host. On the undercloud, nodes are typically reachable directly via their mgmt IPs from the corporate network, so a bastion is unnecessary. Set to `false` if external access requires a jump host.

### `metallb_networks`

```hcl
metallb_networks = [
  {
    pool_name   = "public-pool"
    vlan_id     = 105
    subnet_pool = "PUBLIC-IP-POOL"
  }
]
```

Defines MetalLB IP pools. Each entry creates:
1. An OpenStack network + subnet (allocated from `subnet_pool`)
2. A trunk sub-port on each node (tagged with `vlan_id`)
3. An SVI router providing the L3 gateway for the subnet

| Field | Description |
|-------|-------------|
| `pool_name` | Name used in MetalLB `IPAddressPool` and OpenStack port naming (`<prefix>-<node>-<pool_name>`) |
| `vlan_id` | VLAN tag for the sub-port. Creates interface `metal.<vlan_id>` on nodes |
| `subnet_pool` | OpenStack subnet pool to allocate public IPs from (e.g., `PUBLIC-IP-POOL` for routable public IPs) |

Multiple entries are supported for clusters needing separate IP pools (e.g., public + internal).

**Important:** The MetalLB ports are created without `fixed_ips` — MetalLB manages the IPs, not OpenStack. This means cloud-init does NOT create the VLAN sub-interface automatically. After provisioning, run the `metallb-public-pool` playbook to set up the interface, MAC, and policy-based routing. See `playbooks/metallb-public-pool/README.md`.

## Kubernetes Network Settings

### `subnet_pods` / `subnet_services`

```hcl
subnet_pods     = "10.42.0.0/16"
subnet_services = "10.43.0.0/16"
```

Internal Kubernetes CIDRs (not OpenStack networks). These are passed to kubespray and Calico for pod and service networking. They never appear on the wire — they're encapsulated in VXLAN tunnels over the mgmt VLAN.

### `subnet_nodes`

```hcl
subnet_nodes = "10.2.128.0/24"
```

The hostnet CIDR repeated here for kubespray. Used internally by kubespray for `supplementary_addresses_in_ssl_keys` and node addressing.

## Calico Settings

### `cni_iface`

```hcl
cni_iface = "mgmt.109"
```

The interface Calico uses for the VXLAN tunnel endpoints. Must match the mgmt VLAN interface name. Calico's `nodeAddressAutodetectionV4` uses this to determine which IP to use for the node mesh.

### `calico_interface_autodetect`

```hcl
calico_interface_autodetect = "interface"
```

Method for Calico to discover the node IP. Options:
- `"interface"` — Match by interface name regex (uses `cni_iface`)
- `"first-found"` — Use the first non-loopback, non-docker interface
- `"cidr"` — Match by CIDR pattern (uses `calico_interface_autodetect_cidr`)

For undercloud, `"interface"` is recommended since the mgmt VLAN has a predictable name.

### `calico_encapsulation_type`

```hcl
calico_encapsulation_type = "VXLAN"
```

Pod-to-pod encapsulation. `VXLAN` is required on undercloud since the nodes communicate over a VLAN (not a flat L2 segment) and BGP peering with the fabric isn't available.

### `calico_nat_outgoing`

```hcl
calico_nat_outgoing = true
```

Whether pods SNAT when reaching destinations outside the pod CIDR. Enables pods to reach the internet via the node's default route.

## Post-Provisioning Steps

After `terraform apply` completes:

1. **Run kubespray** — Deploys Kubernetes on the provisioned nodes
2. **Bootstrap Flux** — `flux bootstrap git` to set up GitOps
3. **Run MetalLB playbook** — `playbooks/metallb-public-pool/metallb-public-pool.yml` to configure the VLAN interface, MAC, and routing on all nodes
4. **Restart MetalLB speakers** - Restart the metallb speaker daemonset to force it to re-arp the new metallb interface.
5. **Deploy applications** — Flux reconciles MetalLB, gateway, and services from the overlay

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| MetalLB speaker warns "interfaces don't exist" | `metal.X` VLAN sub-interface not created | Run `metallb-public-pool` playbook (`--tags interface`) |
| Public IP unreachable (traceroute blackholes) | SVI router not advertising route to fabric | Contact undercloud networking team; may need router recreate |
| ARP for MetalLB VIP ignored by switch | Port security: wrong MAC or missing `allowed_address_pairs` | Run playbook (`--tags openstack`) to fix port security |
| Return traffic doesn't reach client | No policy-based routing on node for public subnet | Run playbook (`--tags routing`) |
| `terraform destroy` fails on trunks | Trunk ports disabled by platform | Run `trunk-enable` playbook first |
