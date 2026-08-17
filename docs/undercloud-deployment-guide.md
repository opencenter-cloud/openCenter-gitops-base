# Undercloud Deployment Guide

This guide explains the undercloud-specific configuration in `main.tf` for deploying Kubernetes clusters on the Rackspace undercloud (multi-VLAN trunk-port topology).

## Network Topology Overview

The undercloud uses a trunk-port model where each server gets a single physical NIC carrying multiple VLANs:

```
                          ┌─────────────────────────────────┐
                          │         Physical Server          │
                          │                                  │
  Upstream Switch ────────┤  eno3np0 (trunk parent, native)  │
   (VLAN trunk)           │    ├── eno3np0.109 (VLAN 109)      │  ← Management / Kube-VIP / Calico
                          │    └── metal.105 (VLAN 105)     │  ← MetalLB public IPs
                          │                                  │
                          │  hostnet: 10.2.128.0/24          │  ← Native/untagged, static, default route
                          └─────────────────────────────────┘
```

- **Hostnet** — Native (untagged) network on the trunk parent. Neutron allocates each parent port a fixed IP that Terraform configures statically with the subnet gateway, DNS, default route, and outbound NAT.
- **Mgmt VLAN** — Tagged VLAN for Kubernetes API access (kube-vip), Calico node-to-node, and SSH.
- **MetalLB VLAN(s)** — Tagged VLAN(s) for public-facing LoadBalancer IPs. No IPs assigned by OpenStack; MetalLB manages them via L2 advertisement.

## Undercloud-Specific Settings

These settings come after the standard cluster/server sizing in `main.tf`:

### `hostnet_cidr`

```hcl
hostnet_cidr = "10.2.128.0/24"
```

The CIDR for the native (untagged) host network. Neutron allocates a fixed IP from this subnet to each trunk parent port; Terraform renders that exact allocation, the subnet prefix, gateway, and DNS into netplan as a static configuration. It provides the node's main-table default route and outbound NAT to the internet via an OVN router connected to PUBLICNET.

### `mgmt_vlan_id`

```hcl
mgmt_vlan_id = 109
```

VLAN ID for the management network. This creates a tagged sub-interface (`<trunk_interface_name>.<id>`, for example `eno3np0.109`) on each node. Used for:
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
    allowed_address_pairs = [
      "192.0.2.10",
      "192.0.2.11",
    ]
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
| `vlan_id` | VLAN tag for the sub-port. Defaults to `105` and must be unique across pools |
| `subnet_pool` | OpenStack subnet pool from which the public subnet is allocated |
| `interface_name` | Optional interface override. Defaults to `metal.<vlan_id>` |
| `table_id` | Optional policy-route table override. Defaults to `vlan_id` |
| `rule_priority` | Optional source-policy-rule priority. Defaults to `1000 + vlan_id` |
| `allowed_address_pairs` | Optional extra IP addresses or CIDRs added to every node's pool subport |

Multiple entries are supported for clusters needing separate IP pools (for example, public and internal pools). Pool names, VLAN IDs, interface names, route-table IDs, and policy-rule priorities must be unique.

Terraform automatically adds the dynamically allocated pool CIDR to every control-plane and worker subport as an allowed-address pair. Neutron associates that pair with the subport's own MAC, permitting MetalLB-announced addresses through port security. Use `allowed_address_pairs` only for additional addresses or CIDRs beyond the allocated pool; in most deployments it can be omitted.

The MetalLB ports intentionally have no fixed IPs because MetalLB owns the addresses. For each node, Terraform renders two candidate netplan files under the staging root:

- `/var/lib/undercloud-netplan/etc/netplan/50-cloud-init.yaml` owns the physical trunk parent and management VLAN. The parent uses the explicit `trunk_interface_name` (default `eno3np0`), is assigned `trunk_mtu` (default `9000`), and receives the exact fixed IP, prefix, gateway, and DNS from its Neutron parent-port/subnet allocation. Its default route stays in the main table. The physical NIC is addressed by its stable Linux name because the Neutron parent-port MAC can differ from the bare-metal NIC MAC. The management VLAN keeps the datasource-compatible `<trunk_interface_name>.<mgmt_vlan_id>` name, receives its fixed subport IP/MAC, and places its link-scope and default routes exclusively in the VLAN-numbered table with a source rule at priority `1000 + mgmt_vlan_id`.
- `/var/lib/undercloud-netplan/etc/netplan/60-metallb-public-pools.yaml` owns all MetalLB VLANs. Each pool receives its subport MAC, the same trunk MTU, a link-scope subnet route, an on-link default route in its dedicated table, and a source policy rule.

Cloud-init first stages these templates so the OpenStack datasource configuration remains active for initial management SSH. During the final cloud-init stage, `/usr/local/sbin/apply-undercloud-netplan` validates the complete staged root, backs up the datasource netplan to `/var/lib/undercloud-netplan/original-netplan`, promotes the rendered files, runs `netplan generate` and `netplan apply`, and only then disables datasource network regeneration. The script writes `/var/lib/undercloud-netplan/ready` last; the Kubespray readiness gate refuses to continue if that marker is missing. No reboot is required. When a pre-existing hostnet network is supplied, `trunk_mtu` must match that network's actual MTU.

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
cni_iface = "eno3np0.109"
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

## Provisioning Sequence

`terraform apply` performs the node-side networking steps before Kubernetes bootstrap:

1. **Bootstrap datasource networking** — OpenStack provides initial connectivity on the Neutron-allocated hostnet and management VLAN so the node is reachable during cloud-init.
2. **Validate and activate rendered netplan** — The local cloud-init script validates the staging root, backs up `/etc/netplan`, promotes the base and optional MetalLB files, and applies them without renaming the management interface.
3. **Require the readiness marker** — Kubespray accepts the known recoverable cloud-init status only when `/var/lib/undercloud-netplan/ready` exists. A failed network activation stops provisioning.
4. **Run Kubespray** — Kubernetes starts only after every node has completed cloud-init and activated its policy routing.
5. **Bootstrap Flux and deploy applications** — Run `flux bootstrap git`, then allow Flux to reconcile MetalLB, gateway, and services from the overlay.

Before starting MetalLB speakers or LoadBalancer services, verify the expected `metal.<vlan_id>` interfaces and policy-route tables on the deployed nodes.

### MetalLB Public-Pool Playbook (Existing Nodes and Repair)

The undercloud module now owns the OpenStack allowed-address pairs and node-side netplan for nodes created with this version. The `metallb-public-pool` playbook remains available for:

- Existing nodes created before automatic cloud-init configuration was added
- Repairing or verifying drift on a running node
- Environments where this Terraform module does not create the nodes
- Explicitly applying or removing a pool without rebuilding an instance

This distinction matters because compute resources ignore later `user_data` changes and cloud-init runs only on first boot. Updating `metallb_networks` does not retrofit or remove netplan configuration on existing instances; rebuild those nodes or converge them with the playbook.

Before running it, confirm:

- The OpenStack CLI can use the configured `clouds.yaml` entry.
- The Ansible inventory places every target host in `oc_controlplane_nodes` or `oc_worker_nodes`.
- The management VLAN interface exists and netplan uses the `systemd-networkd` renderer.
- Terraform created a trunk subport for every pool/node pair. The playbook verifies that each port exists and has a valid MAC, but it does not validate trunk membership.

Copy the repository example to a cluster-specific location instead of putting cluster values in the playbook defaults:

```bash
cp playbooks/metallb-public-pool/vars.yml \
  /path/to/cluster-metallb-public-pool-vars.yml
```

Populate it from `mgmt_vlan_id`, each `metallb_networks` entry, the allocated OpenStack subnet and SVI gateway, and the node subport names or UUIDs:

```yaml
os_cloud: example-undercloud

mgmt_vlan_id: 109
mgmt_interface: "eno3np0.{{ mgmt_vlan_id }}"

metallb_public_pools:
  - name: public-pool
    vlan_id: 105
    subnet: "192.0.2.0/28"
    gateway: "192.0.2.1"

    # Optional overrides (default behavior shown inline):
    # interface_name: "metal.105"   # defaults to metal.<vlan_id>
    # table_id: 105                 # defaults to <vlan_id>
    # rule_priority: 1105           # defaults to 1000 + <vlan_id>
    # parent_interface: eno3np0     # defaults to mgmt_interface's parent
    # mtu: 9000                     # defaults to the trunk-parent MTU

    node_ports:
      - host: example-cp0
        port: example-cp0-public-pool
      - host: example-cp1
        port: example-cp1-public-pool
      - host: example-wn0
        port: example-wn0-public-pool
```

Add another mapping under `metallb_public_pools` for each Terraform `metallb_networks` entry. Pool names, VLAN IDs, interface names, route-table IDs, and rule priorities must be unique. Hosts must match the inventory, ports must be unique, the subnet must be a strict network CIDR, and the gateway must be a usable address inside that subnet.

Set the inventory, vars file, and playbook paths, then validate before applying anything:

```bash
export ANSIBLE_INVENTORY=/path/to/inventory.yaml
VARS=/path/to/cluster-metallb-public-pool-vars.yml
PLAYBOOK=playbooks/metallb-public-pool/metallb-public-pool.yml

# Non-applying input, OpenStack port, trunk-parent, and candidate-netplan validation.
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags validate

# Full convergence: OpenStack allowed-address pairs, node netplan, and verification.
ansible-playbook "$PLAYBOOK" -e @"$VARS"

# Read-only runtime verification after convergence or a reboot.
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags verify
```

For a first deployment, limit node convergence to one host before rolling out to the remaining nodes:

```bash
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags nodes --limit example-wn0
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags nodes
```

The `nodes` tag still performs read-only OpenStack lookups to obtain port MACs. Re-running a converged configuration should report no changes.

#### Playbook Tags

| Tag | OpenStack changes | Node changes | Purpose |
|-----|-------------------|--------------|---------|
| `configure` | Yes | Yes | Explicit full convergence; also the default untagged run |
| `openstack` | Yes | No | Add missing exact allowed-address pairs |
| `nodes` | No | Yes | Render, validate, apply, and verify node netplan |
| `validate` | No | Temporary files only | Validate inputs, port lookups, trunk discovery, and candidate netplan |
| `verify` | No | No | Verify runtime interfaces, routes, and policy rules |
| `destroy` | Yes | Yes | Remove managed netplan/runtime state and configured allowed-address pairs |

`verify` checks runtime state; it does not prove that the managed netplan file exists or matches the current template. Use `--tags nodes` to converge and restore persisted configuration.

The `destroy` tasks also carry Ansible's `never` tag and run only when explicitly requested:

```bash
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags destroy
```

Destroy removes the consolidated netplan, configured runtime interfaces/rules/routes, and the exact configured OpenStack allowed-address pairs. It does not delete OpenStack ports, trunks, or subports. Node destroy flushes each configured route table, so table IDs must not be shared with unrelated routes. A node-limited destroy excludes the `localhost` plays and therefore does not remove OpenStack allowed-address pairs.

See `playbooks/metallb-public-pool/README.md` for the complete variable constraints and persistence test procedure.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| MetalLB speaker warns that `metal.X` does not exist | First-boot network activation failed, or runtime state drifted | Check `cloud-init status --long`, `/var/log/cloud-init-output.log`, and `/var/lib/undercloud-netplan/ready`; repair existing nodes with the playbook's `nodes` tag |
| Undercloud netplan activation fails | The staged candidate is invalid or `netplan apply` failed | Inspect `/var/lib/undercloud-netplan/etc/netplan/` and `/var/lib/undercloud-netplan/original-netplan`, correct `mgmt_vlan_id`/`metallb_networks`, and rebuild the node |
| OpenStack port lookup fails in the playbook | Wrong `os_cloud`, port name/UUID, or missing subport | Correct the vars file and confirm Terraform created every pool/node subport |
| ARP for a MetalLB VIP is blocked | The pool-CIDR/MAC allowed-address pair is missing or stale | Apply Terraform; use the playbook's `openstack` tag for existing or non-module-managed ports |
| Return traffic does not reach the client | The VLAN route table or source policy rule is missing or stale | Run `--tags verify`; repair with `--tags nodes` |
| Public IP traffic reaches the SVI but not the fabric | The SVI router route is not being advertised upstream | Contact the undercloud networking team; the router may need correction |
| Configuration disappears after a reboot | The consolidated netplan file is absent or stale | Run `--tags nodes`, then repeat the persistence checks in the playbook README |
| `terraform destroy` fails on trunks | Trunk ports are disabled by the platform | Run the `trunk-enable` playbook first |
