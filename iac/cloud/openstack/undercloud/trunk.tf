###############################################################################
# Trunk Port Layer
# Creates parent ports, mgmt subports, MetalLB subports, and trunk resources
# for control plane and worker instances.
###############################################################################

locals {
  master_count = var.size_master.count
  worker_count = var.size_worker.count

  # Flatten master × metallb combinations for subport creation
  master_metallb_ports = flatten([
    for idx in range(local.master_count) : [
      for name, net in local.metallb_map : {
        master_idx            = idx
        pool_name             = name
        network_id            = openstack_networking_network_v2.metallb[name].id
        vlan_id               = net.vlan_id
        allowed_address_pairs = net.allowed_address_pairs
      }
    ]
  ])

  # Flatten worker × metallb combinations for subport creation
  worker_metallb_ports = flatten([
    for idx in range(local.worker_count) : [
      for name, net in local.metallb_map : {
        worker_idx            = idx
        pool_name             = name
        network_id            = openstack_networking_network_v2.metallb[name].id
        vlan_id               = net.vlan_id
        allowed_address_pairs = net.allowed_address_pairs
      }
    ]
  ])
}

###############################################################################
# Control Plane — Parent Ports (hostnet, native/untagged)
###############################################################################

resource "openstack_networking_port_v2" "parent_master" {
  count = local.master_count

  name       = "${var.naming_prefix}${var.node_master}${count.index}"
  network_id = local.hostnet_network_id

  fixed_ip {
    subnet_id = local.hostnet_subnet_id
  }

  security_group_ids = [
    module.secgroup.controlplane_id,
    module.secgroup.master_id,
  ]
}

###############################################################################
# Control Plane — Mgmt Subports (VLAN-tagged management network)
###############################################################################

resource "openstack_networking_port_v2" "subport_mgmt_master" {
  count = local.master_count

  name       = "${var.naming_prefix}${var.node_master}${count.index}-mgmt"
  network_id = openstack_networking_network_v2.mgmt.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.mgmt.id
  }

  # kube-vip VIP address
  allowed_address_pairs {
    ip_address = local.kube_vip_address
  }

  # Mgmt subnet CIDR
  allowed_address_pairs {
    ip_address = local.mgmt_subnet_cidr
  }

  # Pod subnet CIDR
  allowed_address_pairs {
    ip_address = var.subnet_pods
  }

  # Service subnet CIDR
  allowed_address_pairs {
    ip_address = var.subnet_services
  }

  security_group_ids = [
    module.secgroup.controlplane_id,
    module.secgroup.master_id,
  ]
}

###############################################################################
# Control Plane — MetalLB Subports (one per MetalLB network per master)
###############################################################################

resource "openstack_networking_port_v2" "subport_metallb_master" {
  for_each = { for p in local.master_metallb_ports : "${p.master_idx}-${p.pool_name}" => p }

  name        = "${var.naming_prefix}${var.node_master}${each.value.master_idx}-${each.value.pool_name}"
  network_id  = each.value.network_id
  no_fixed_ip = true

  # Permit the complete dynamically allocated pool through port security.
  # Neutron uses this subport's MAC when mac_address is omitted.
  dynamic "allowed_address_pairs" {
    for_each = concat(
      [openstack_networking_subnet_v2.metallb[each.value.pool_name].cidr],
      each.value.allowed_address_pairs,
    )
    content {
      ip_address = allowed_address_pairs.value
    }
  }

  security_group_ids = [
    module.secgroup.controlplane_id,
    module.secgroup.master_id,
  ]
}

###############################################################################
# Control Plane — Trunk Resources
###############################################################################

resource "openstack_networking_trunk_v2" "master" {
  count = local.master_count

  name    = "${var.naming_prefix}${var.node_master}${count.index}"
  port_id = openstack_networking_port_v2.parent_master[count.index].id

  # Mgmt subport
  sub_port {
    port_id           = openstack_networking_port_v2.subport_mgmt_master[count.index].id
    segmentation_id   = var.mgmt_vlan_id
    segmentation_type = "vlan"
  }

  # MetalLB subports
  dynamic "sub_port" {
    for_each = [for p in local.master_metallb_ports : p if p.master_idx == count.index]
    content {
      port_id           = openstack_networking_port_v2.subport_metallb_master["${sub_port.value.master_idx}-${sub_port.value.pool_name}"].id
      segmentation_id   = sub_port.value.vlan_id
      segmentation_type = "vlan"
    }
  }
}

###############################################################################
# Workers — Parent Ports (hostnet, native/untagged)
###############################################################################

resource "openstack_networking_port_v2" "parent_worker" {
  count = local.worker_count

  name       = "${var.naming_prefix}${var.node_worker}${count.index}"
  network_id = local.hostnet_network_id

  fixed_ip {
    subnet_id = local.hostnet_subnet_id
  }

  security_group_ids = [
    module.secgroup.controlplane_id,
    module.secgroup.worker_id,
  ]
}

###############################################################################
# Workers — Mgmt Subports (VLAN-tagged management network)
# Note: Workers do NOT get kube-vip VIP or mgmt subnet CIDR in
# allowed_address_pairs (only pod and service subnets).
###############################################################################

resource "openstack_networking_port_v2" "subport_mgmt_worker" {
  count = local.worker_count

  name       = "${var.naming_prefix}${var.node_worker}${count.index}-mgmt"
  network_id = openstack_networking_network_v2.mgmt.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.mgmt.id
  }

  # Pod subnet CIDR
  allowed_address_pairs {
    ip_address = var.subnet_pods
  }

  # Service subnet CIDR
  allowed_address_pairs {
    ip_address = var.subnet_services
  }

  security_group_ids = [
    module.secgroup.controlplane_id,
    module.secgroup.worker_id,
  ]
}

###############################################################################
# Workers — MetalLB Subports (one per MetalLB network per worker)
###############################################################################

resource "openstack_networking_port_v2" "subport_metallb_worker" {
  for_each = { for p in local.worker_metallb_ports : "${p.worker_idx}-${p.pool_name}" => p }

  name        = "${var.naming_prefix}${var.node_worker}${each.value.worker_idx}-${each.value.pool_name}"
  network_id  = each.value.network_id
  no_fixed_ip = true

  # Permit the complete dynamically allocated pool through port security.
  # Neutron uses this subport's MAC when mac_address is omitted.
  dynamic "allowed_address_pairs" {
    for_each = concat(
      [openstack_networking_subnet_v2.metallb[each.value.pool_name].cidr],
      each.value.allowed_address_pairs,
    )
    content {
      ip_address = allowed_address_pairs.value
    }
  }

  security_group_ids = [
    module.secgroup.controlplane_id,
    module.secgroup.worker_id,
  ]
}

###############################################################################
# Workers — Trunk Resources
###############################################################################

resource "openstack_networking_trunk_v2" "worker" {
  count = local.worker_count

  name    = "${var.naming_prefix}${var.node_worker}${count.index}"
  port_id = openstack_networking_port_v2.parent_worker[count.index].id

  # Mgmt subport
  sub_port {
    port_id           = openstack_networking_port_v2.subport_mgmt_worker[count.index].id
    segmentation_id   = var.mgmt_vlan_id
    segmentation_type = "vlan"
  }

  # MetalLB subports
  dynamic "sub_port" {
    for_each = [for p in local.worker_metallb_ports : p if p.worker_idx == count.index]
    content {
      port_id           = openstack_networking_port_v2.subport_metallb_worker["${sub_port.value.worker_idx}-${sub_port.value.pool_name}"].id
      segmentation_id   = sub_port.value.vlan_id
      segmentation_type = "vlan"
    }
  }
}
