# Managed by Terraform: iac/cloud/openstack/undercloud
# Complete netplan configuration: the Neutron-allocated hostnet address and
# gateway are configured statically on the parent while the management and
# MetalLB networks use dedicated policy-routing tables. The parent is selected
# by its stable name because Ironic assigns its physical MAC after Terraform
# renders user-data.
network:
  version: 2
  renderer: networkd
  ethernets:
    "${trunk_interface_name}":
      addresses:
        - "${hostnet_address}"
      dhcp4: false
      dhcp6: false
      mtu: ${trunk_mtu}
%{if length(dns_nameservers) > 0~}
      nameservers:
        addresses:
%{for server in dns_nameservers~}
          - "${server}"
%{endfor~}
        search: []
%{endif~}
      routes:
        - to: default
          via: "${hostnet_gateway}"
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
