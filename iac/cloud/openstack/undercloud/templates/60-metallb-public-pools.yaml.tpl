# Managed by Terraform: iac/cloud/openstack/undercloud
network:
  version: 2
  renderer: networkd
  vlans:
%{for net in metallb_networks~}
    "${net.interface_name}":
      id: ${net.vlan_id}
      link: "${trunk_interface_name}"
      macaddress: "${net.mac_address}"
      mtu: ${trunk_mtu}
      dhcp4: false
      dhcp6: false
      optional: true
      routes:
        - to: "${net.subnet}"
          scope: link
          table: ${net.table_id}
        - to: default
          via: "${net.gateway}"
          on-link: true
          table: ${net.table_id}
      routing-policy:
        - from: "${net.subnet}"
          table: ${net.table_id}
          priority: ${net.rule_priority}
%{endfor~}
