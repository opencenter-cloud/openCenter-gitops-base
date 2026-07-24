# MetalLB Public Pool VLAN Setup

Configures the MetalLB public-pool VLAN interface and policy-based routing on undercloud nodes.

## Why is this needed?

On the undercloud topology, MetalLB public-pool OpenStack ports are created **without `fixed_ips`** (by design — MetalLB manages the IPs, not OpenStack). Because there's no IP on the port, cloud-init/netplan never creates the VLAN sub-interface on the node OS. This playbook fills that gap.

## What it does

| Step | Description |
|------|-------------|
| **OpenStack** | Adds `allowed_address_pairs` on MetalLB ports so port security allows MetalLB VIPs. Discovers port MACs. |
| **Interface** | Creates `metal.<vlan_id>` VLAN sub-interface on the trunk parent, sets MAC to match the OpenStack port, sets MTU. |
| **Routing** | Configures policy-based routing: separate routing table, default via SVI gateway, ip rule matching the public subnet. |
| **Persist** | Writes netplan config + networkd-dispatcher script so everything survives reboots. |

## Prerequisites

- OpenStack CLI configured with a `clouds.yaml` entry (default: `uc-oc-stage`)
- SSH access to cluster nodes via the inventory
- The undercloud Terraform module has already created the cluster (ports, trunks, etc.)

## Configuration

Edit `vars.yml` to match your cluster:

```yaml
os_cloud: uc-oc-stage           # OpenStack cloud name
metallb_vlan_id: 105            # VLAN ID for public-pool
metallb_subnet: "72.4.119.16/28" # Subnet allocated from PUBLIC-IP-POOL
metallb_gateway: "72.4.119.17"  # SVI gateway IP
node_port_names:                # OpenStack port names per node
  - sandbox-cp0-public-pool
  - ...
host_port_map:                  # inventory hostname → port name
  sandbox-cp0: sandbox-cp0-public-pool
  ...
```

You can also pass an external vars file:
```bash
ansible-playbook -i <inventory> playbooks/metallb-public-pool/metallb-public-pool.yml \
  -e @/path/to/my-cluster-vars.yml
```

## Usage

```bash
# Full run (all steps)
ansible-playbook -i <inventory> playbooks/metallb-public-pool/metallb-public-pool.yml

# Only OpenStack port security
ansible-playbook -i <inventory> playbooks/metallb-public-pool/metallb-public-pool.yml --tags openstack

# Only create interfaces
ansible-playbook -i <inventory> playbooks/metallb-public-pool/metallb-public-pool.yml --tags interface

# Only routing
ansible-playbook -i <inventory> playbooks/metallb-public-pool/metallb-public-pool.yml --tags routing

# Only persistence configs
ansible-playbook -i <inventory> playbooks/metallb-public-pool/metallb-public-pool.yml --tags persist

# Destroy everything (tear down for re-testing)
ansible-playbook -i <inventory> playbooks/metallb-public-pool/metallb-public-pool.yml --tags destroy
```

## Tags

| Tag | Scope | Description |
|-----|-------|-------------|
| `openstack` | localhost | Port security + MAC discovery |
| `interface` | nodes | VLAN interface creation + MAC + MTU |
| `routing` | nodes | Policy-based routing setup |
| `persist` | nodes | Netplan + dispatcher scripts |
| `destroy` | nodes | Remove all changes (must be explicitly requested) |

## Notes

- The `destroy` tag uses Ansible's `never` special tag — it won't run unless explicitly passed via `--tags destroy`.
- The mgmt VLAN (109) is fully handled by cloud-init and does NOT need this playbook.
- This playbook is idempotent — safe to run multiple times.
- After a fresh Terraform apply, run this playbook before deploying MetalLB services that use the public-pool.
