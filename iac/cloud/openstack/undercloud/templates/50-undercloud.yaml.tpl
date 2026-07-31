# Managed by Terraform: iac/cloud/openstack/undercloud
network:
  version: 2
  renderer: networkd
  ethernets:
    "${trunk_interface_name}":
      dhcp4: true
      mtu: ${trunk_mtu}
  vlans:
    "${mgmt_interface_name}":
      addresses:
        - "${mgmt_address}"
      id: ${mgmt_vlan_id}
      link: "${trunk_interface_name}"
      macaddress: "${mgmt_mac_address}"
      mtu: ${trunk_mtu}
      dhcp4: false
      dhcp6: false
      optional: true
      nameservers:
        addresses:
%{for server in dns_nameservers~}
          - "${server}"
%{endfor~}
        search: []
      routes:
        - to: "${mgmt_subnet_cidr}"
          scope: link
          table: ${mgmt_table_id}
        - to: default
          via: "${mgmt_gateway}"
          on-link: true
          table: ${mgmt_table_id}
      routing-policy:
        - from: "${mgmt_subnet_cidr}"
          table: ${mgmt_table_id}
          priority: ${mgmt_rule_priority}
