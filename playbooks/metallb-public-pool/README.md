# MetalLB Public-Pool VLAN Setup

Configures one or more MetalLB public-pool VLANs and source-based routing tables on undercloud Kubernetes nodes.

Netplan and `systemd-networkd` are the only sources of truth for node networking. The playbook does not create interfaces or routes with imperative `ip link`, `ip route`, or `ip rule` commands during configuration.

## Why this is needed

MetalLB public-pool OpenStack ports are created without `fixed_ips`. Because OpenStack does not assign an address, cloud-init does not create the VLAN interface on the node. This playbook supplies the missing netplan configuration while preserving OpenStack port-security enforcement.

## What it manages

- OpenStack `allowed_address_pairs` for every pool and node port
- VLAN interface ID, parent, MAC, and MTU
- A dedicated route table per pool
- A link-scope route for the public subnet
- An on-link default route through the SVI gateway
- A source policy rule with an explicit priority
- Complete node and OpenStack teardown

## Prerequisites

- OpenStack CLI and a working `clouds.yaml` entry
- SSH and sudo access to the target nodes
- Netplan using the `systemd-networkd` renderer
- Existing management VLAN on the trunk parent
- OpenStack trunk subports already created for every configured pool/node pair

## Configuration

Pass a cluster-specific vars file with `-e @<file>`. A node may participate in multiple pools, and every OpenStack port identifier is overrideable.

```yaml
os_cloud: uc-oc-stage

mgmt_vlan_id: 109
mgmt_interface: "mgmt.{{ mgmt_vlan_id }}"

metallb_public_pools:
  - name: public-pool
    vlan_id: 105
    interface_name: metal.105
    subnet: "72.4.119.16/28"
    gateway: "72.4.119.17"
    table_id: 105
    rule_priority: 1105
    node_ports:
      - host: sandbox-cp0
        port: sandbox-cp0-public-pool
      - host: sandbox-cp1
        port: sandbox-cp1-public-pool

  - name: second-public-pool
    vlan_id: 205
    interface_name: metal.205
    subnet: "192.0.2.0/28"
    gateway: "192.0.2.1"
    table_id: 205
    rule_priority: 1205
    node_ports:
      - host: sandbox-wn0
        port: 00000000-0000-0000-0000-000000000000
```

`port` may be an OpenStack port name or UUID. No naming convention is assumed.

Defaults when omitted:

```yaml
table_id: <vlan_id>
rule_priority: 1000 + <vlan_id>
interface_name: "metal.<vlan_id>"
```

Rule priorities, table IDs, interface names, VLAN IDs, and pool names must be unique. Defaults are convenience values and remain fully overrideable.

A pool may optionally override the discovered parent interface or MTU:

```yaml
parent_interface: eno3np0
mtu: 9000
```

## Usage

```bash
export ANSIBLE_INVENTORY=/path/to/inventory.yaml
VARS=/path/to/metallb-public-pool-vars.yml
PLAYBOOK=playbooks/metallb-public-pool/metallb-public-pool.yml

# Validate variables, OpenStack ports, trunk discovery, and candidate netplan.
# Candidate files are rendered under a temporary root and are not applied.
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags validate

# Full convergence: OpenStack followed by nodes and verification.
ansible-playbook "$PLAYBOOK" -e @"$VARS"

# Explicit full convergence tag.
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags configure

# OpenStack allowed-address pairs only.
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags openstack

# Node netplan configuration and verification only.
# This still performs read-only OpenStack lookups to obtain port MACs.
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags nodes

# Read-only runtime verification.
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags verify

# Complete node and OpenStack teardown.
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags destroy
```

## Tags

| Tag | Mutates OpenStack | Mutates nodes | Description |
|---|---:|---:|---|
| `configure` | Yes | Yes | Complete convergence and verification |
| `openstack` | Yes | No | Add missing allowed-address pairs |
| `nodes` | No | Yes | Render, validate, apply, and verify netplan |
| `validate` | No | Temporary files only | Validate inputs, ports, trunk discovery, and candidate netplan |
| `verify` | No | No | Verify interfaces, routes, and policy rules |
| `destroy` | Yes | Yes | Remove managed netplan, runtime residue, and allowed-address pairs |

The destructive tasks also carry Ansible's `never` tag and run only when `--tags destroy` is explicitly supplied.

## Safety and convergence behavior

- Nodes are processed with `serial: 1` and `any_errors_fatal: true`.
- Candidate netplan is validated with the installed netplan version before `/etc/netplan` is changed.
- `netplan apply` runs only when configuration or runtime drift requires it.
- After applying netplan, the playbook waits for the node connection and verifies every interface, route, and policy rule.
- Re-running a converged configuration should report no changes.

## Persistence tests

Before approving a new cluster, test one node first with `--limit`:

```bash
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags validate --limit sandbox-wn0
ansible-playbook "$PLAYBOOK" -e @"$VARS" --tags nodes --limit sandbox-wn0
```

Then verify these lifecycle operations:

```bash
systemctl restart systemd-networkd
systemctl stop systemd-networkd
systemctl start systemd-networkd
networkctl reload
networkctl reconfigure metal.105
```

After each operation:

```bash
networkctl status metal.105
ip route show table 105
ip rule show priority 1105
```

Finally reboot the node and repeat the checks before rolling out to the rest of the cluster.
