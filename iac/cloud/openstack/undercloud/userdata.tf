locals {
  undercloud_cloudinit_common = {
    ssh_authorized_keys = var.ssh_authorized_keys
    ntp_servers         = var.ntp_servers
    ca_certificates     = join("\n", compact([var.openstack_ca, (var.services_ca_enabled ? module.ca[0].certificate : ""), var.ca_certificates]))
  }

  undercloud_netplan_common = {
    trunk_interface_name = var.trunk_interface_name
    trunk_mtu            = var.trunk_mtu
    hostnet_subnet_cidr  = data.openstack_networking_subnet_v2.hostnet.cidr
    hostnet_gateway      = data.openstack_networking_subnet_v2.hostnet.gateway_ip
    mgmt_interface_name  = "${var.trunk_interface_name}.${var.mgmt_vlan_id}"
    mgmt_vlan_id         = var.mgmt_vlan_id
    mgmt_subnet_cidr     = openstack_networking_subnet_v2.mgmt.cidr
    mgmt_gateway         = openstack_networking_subnet_v2.mgmt.gateway_ip
    mgmt_table_id        = var.mgmt_vlan_id
    mgmt_rule_priority   = 1000 + var.mgmt_vlan_id
    subnet_pods          = var.subnet_pods
    subnet_services      = var.subnet_services
    dns_nameservers      = data.openstack_networking_subnet_v2.hostnet.dns_nameservers
  }

  master_metallb_cloudinit = {
    for idx in range(local.master_count) : idx => [
      for name, net in local.metallb_map : {
        interface_name = net.interface_name
        vlan_id        = net.vlan_id
        table_id       = net.table_id
        rule_priority  = net.rule_priority
        subnet         = openstack_networking_subnet_v2.metallb[name].cidr
        gateway        = openstack_networking_subnet_v2.metallb[name].gateway_ip
        mac_address    = openstack_networking_port_v2.subport_metallb_master["${idx}-${name}"].mac_address
      }
    ]
  }

  worker_metallb_cloudinit = {
    for idx in range(local.worker_count) : idx => [
      for name, net in local.metallb_map : {
        interface_name = net.interface_name
        vlan_id        = net.vlan_id
        table_id       = net.table_id
        rule_priority  = net.rule_priority
        subnet         = openstack_networking_subnet_v2.metallb[name].cidr
        gateway        = openstack_networking_subnet_v2.metallb[name].gateway_ip
        mac_address    = openstack_networking_port_v2.subport_metallb_worker["${idx}-${name}"].mac_address
      }
    ]
  }

  additional_worker_metallb_cloudinit = {
    for instance_key, instance in local.additional_pool_instances_map : instance_key => [
      for name, net in local.metallb_map : {
        interface_name = net.interface_name
        vlan_id        = net.vlan_id
        table_id       = net.table_id
        rule_priority  = net.rule_priority
        subnet         = openstack_networking_subnet_v2.metallb[name].cidr
        gateway        = openstack_networking_subnet_v2.metallb[name].gateway_ip
        mac_address    = openstack_networking_port_v2.subport_metallb_additional["${instance.pool_name}-${instance.instance_idx}-${name}"].mac_address
      }
    ]
  }

  master_netplan = {
    for idx in range(local.master_count) : idx => merge(local.undercloud_netplan_common, {
      hostnet_address  = "${openstack_networking_port_v2.parent_master[idx].all_fixed_ips[0]}/${split("/", local.undercloud_netplan_common.hostnet_subnet_cidr)[1]}"
      mgmt_mac_address = openstack_networking_port_v2.subport_mgmt_master[idx].mac_address
      mgmt_address     = "${openstack_networking_port_v2.subport_mgmt_master[idx].all_fixed_ips[0]}/${split("/", local.mgmt_subnet_cidr)[1]}"
      metallb_networks = local.master_metallb_cloudinit[idx]
    })
  }

  worker_netplan = {
    for idx in range(local.worker_count) : idx => merge(local.undercloud_netplan_common, {
      hostnet_address  = "${openstack_networking_port_v2.parent_worker[idx].all_fixed_ips[0]}/${split("/", local.undercloud_netplan_common.hostnet_subnet_cidr)[1]}"
      mgmt_mac_address = openstack_networking_port_v2.subport_mgmt_worker[idx].mac_address
      mgmt_address     = "${openstack_networking_port_v2.subport_mgmt_worker[idx].all_fixed_ips[0]}/${split("/", local.mgmt_subnet_cidr)[1]}"
      metallb_networks = local.worker_metallb_cloudinit[idx]
    })
  }

  additional_worker_netplan = {
    for instance_key, instance in local.additional_pool_instances_map : instance_key => merge(local.undercloud_netplan_common, {
      hostnet_address  = "${openstack_networking_port_v2.parent_additional[instance_key].all_fixed_ips[0]}/${split("/", local.undercloud_netplan_common.hostnet_subnet_cidr)[1]}"
      mgmt_mac_address = openstack_networking_port_v2.subport_mgmt_additional[instance_key].mac_address
      mgmt_address     = "${openstack_networking_port_v2.subport_mgmt_additional[instance_key].all_fixed_ips[0]}/${split("/", local.mgmt_subnet_cidr)[1]}"
      metallb_networks = local.additional_worker_metallb_cloudinit[instance_key]
    })
  }

  master_cloudinit = {
    for idx, netplan in local.master_netplan : idx => merge(local.undercloud_cloudinit_common, {
      undercloud_netplan = templatefile("${path.module}/templates/50-undercloud.yaml.tpl", netplan)
      metallb_netplan    = length(netplan.metallb_networks) > 0 ? templatefile("${path.module}/templates/60-metallb-public-pools.yaml.tpl", netplan) : ""
    })
  }

  worker_cloudinit = {
    for idx, netplan in local.worker_netplan : idx => merge(local.undercloud_cloudinit_common, {
      undercloud_netplan = templatefile("${path.module}/templates/50-undercloud.yaml.tpl", netplan)
      metallb_netplan    = length(netplan.metallb_networks) > 0 ? templatefile("${path.module}/templates/60-metallb-public-pools.yaml.tpl", netplan) : ""
    })
  }

  additional_worker_cloudinit = {
    for instance_key, netplan in local.additional_worker_netplan : instance_key => merge(local.undercloud_cloudinit_common, {
      undercloud_netplan = templatefile("${path.module}/templates/50-undercloud.yaml.tpl", netplan)
      metallb_netplan    = length(netplan.metallb_networks) > 0 ? templatefile("${path.module}/templates/60-metallb-public-pools.yaml.tpl", netplan) : ""
    })
  }
}

data "cloudinit_config" "undercloud_ubuntu24_master" {
  count = local.master_count

  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/undercloud-ubuntu24-init.tpl", local.master_cloudinit[count.index])
  }
}

data "cloudinit_config" "undercloud_ubuntu24_worker" {
  count = local.worker_count

  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/undercloud-ubuntu24-init.tpl", local.worker_cloudinit[count.index])
  }
}

data "cloudinit_config" "undercloud_ubuntu24_additional_worker" {
  for_each = local.additional_pool_instances_map

  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/undercloud-ubuntu24-init.tpl", local.additional_worker_cloudinit[each.key])
  }
}
