#cloud-config
%{if ca_certificates != ""~}
ca_certs:
  trusted:
  - |
   ${indent(3, ca_certificates)}
%{endif~}

package_update: true
package_upgrade: true
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg-agent
  - software-properties-common
  - jq
  - networkd-dispatcher

ssh_authorized_keys:
%{for key in ssh_authorized_keys~}
  - ${key}
%{endfor~}

ntp:
  enabled: true
  servers:
%{for server in ntp_servers~}
    - ${server}
%{endfor~}

write_files:
  - content: |
      #!/usr/bin/env python3
      """Rewrite netplan VLAN interfaces to predictable names.

      Identifies VLAN interfaces in the netplan configuration by matching
      each subport's VLAN ID and renames them to:
        - mgmt.{mgmt_vlan_id} for the management VLAN
        - metal.{vlan_id} for each MetalLB VLAN
      """
      import glob
      import sys
      import yaml

      NETPLAN_DIR = "/etc/netplan"
      MGMT_VLAN_ID = ${mgmt_vlan_id}
      METALLB_VLANS = {
      %{for net in metallb_networks~}
          ${net.vlan_id}: "metal.${net.vlan_id}",
      %{endfor~}
      }

      # Build the full rename map: vlan_id -> desired interface name
      RENAME_MAP = {
          MGMT_VLAN_ID: "mgmt.%d" % MGMT_VLAN_ID,
      }
      RENAME_MAP.update(METALLB_VLANS)


      def find_netplan_config():
          """Find the netplan config file (typically 50-cloud-init.yaml)."""
          candidates = sorted(glob.glob(NETPLAN_DIR + "/*.yaml"))
          if not candidates:
              candidates = sorted(glob.glob(NETPLAN_DIR + "/*.yml"))
          return candidates[0] if candidates else None


      def rewrite_vlans(config_path):
          """Read netplan config, rename VLAN interfaces, write back."""
          with open(config_path, "r") as f:
              config = yaml.safe_load(f)

          if not config:
              return False

          network = config.get("network", {})
          vlans = network.get("vlans", {})

          if not vlans:
              return False

          changed = False
          new_vlans = {}

          for iface_name, iface_config in vlans.items():
              vlan_id = iface_config.get("id")
              if vlan_id in RENAME_MAP:
                  desired_name = RENAME_MAP[vlan_id]
                  if iface_name != desired_name:
                      new_vlans[desired_name] = iface_config
                      changed = True
                  else:
                      new_vlans[iface_name] = iface_config

                  # For the mgmt VLAN, suppress the default route by removing
                  # gateway4/gateway6 and any default routes from the config.
                  # This prevents netplan from installing a competing default
                  # route on the mgmt interface.
                  if vlan_id == MGMT_VLAN_ID:
                      target = new_vlans.get(desired_name, new_vlans.get(iface_name))
                      if target:
                          if "gateway4" in target:
                              del target["gateway4"]
                              changed = True
                          if "gateway6" in target:
                              del target["gateway6"]
                              changed = True
                          # Remove default routes from routes list
                          if "routes" in target:
                              target["routes"] = [
                                  r for r in target["routes"]
                                  if r.get("to", "") not in ("default", "0.0.0.0/0", "::/0")
                              ]
                              if not target["routes"]:
                                  del target["routes"]
                              changed = True
              else:
                  # Keep interfaces that don't match any known VLAN ID
                  new_vlans[iface_name] = iface_config

          if not changed:
              return False

          config["network"]["vlans"] = new_vlans

          with open(config_path, "w") as f:
              yaml.dump(config, f, default_flow_style=False)

          return True


      def main():
          config_path = find_netplan_config()
          if not config_path:
              print("No netplan configuration file found, skipping.")
              sys.exit(1)

          if rewrite_vlans(config_path):
              print("Netplan VLAN interfaces renamed successfully.")
              sys.exit(0)
          else:
              print("No matching VLAN interfaces found to rename, skipping.")
              sys.exit(1)


      if __name__ == "__main__":
          main()
    path: /usr/local/sbin/rewrite-netplan-vlans
    permissions: '0755'
    owner: root:root
  - content: |
      #!/bin/bash
      # Policy-based routing for the mgmt VLAN interface.
      # Ensures return traffic for connections arriving on mgmt.X replies via
      # the mgmt SVI gateway, preventing asymmetric routing when the node also
      # has a default route on the hostnet interface.
      MGMT_IFACE="mgmt.${mgmt_vlan_id}"
      MGMT_GATEWAY="${mgmt_svi_gateway}"
      MGMT_SUBNET="${mgmt_subnet_cidr}"
      TABLE_ID=${mgmt_vlan_id}

      if [ "$$IFACE" = "$$MGMT_IFACE" ] && [ -n "$$MGMT_GATEWAY" ]; then
        # Remove any default route that DHCP/netplan might have added on this iface
        ip route del default dev "$$IFACE" 2>/dev/null || true

        # Get the IP assigned to the mgmt interface
        MGMT_IP=$(ip -4 addr show dev "$$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

        if [ -n "$$MGMT_IP" ]; then
          # Ensure routing table entry for the VLAN ID exists
          grep -q "^$${TABLE_ID} mgmt" /etc/iproute2/rt_tables 2>/dev/null || \
            echo "$${TABLE_ID} mgmt" >> /etc/iproute2/rt_tables

          # Set up policy routing: traffic from mgmt IP uses mgmt table
          ip rule del from "$$MGMT_IP" table "$$TABLE_ID" 2>/dev/null || true
          ip rule add from "$$MGMT_IP" table "$$TABLE_ID" priority 100

          # Populate the mgmt routing table
          ip route replace "$$MGMT_SUBNET" dev "$$IFACE" table "$$TABLE_ID"
          ip route replace default via "$$MGMT_GATEWAY" dev "$$IFACE" table "$$TABLE_ID"
        fi
      fi
    path: /etc/networkd-dispatcher/routable.d/50-mgmt-policy-route
    permissions: '0755'
    owner: root:root

runcmd:
  - /usr/local/sbin/rewrite-netplan-vlans || true
  - netplan generate

power_state:
  mode: reboot
  timeout: 30
  message: "Rebooting to activate rewritten netplan configuration"
  condition: true
