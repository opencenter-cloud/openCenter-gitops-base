###############################################################################
# Hostnet Network Resources
# (Native/untagged network for outbound NAT via OVN router)
###############################################################################

resource "openstack_networking_network_v2" "hostnet" {
  count = var.hostnet_network_id == "" ? 1 : 0
  name  = "${var.naming_prefix}hostnet"
}

resource "openstack_networking_subnet_v2" "hostnet" {
  count      = var.hostnet_subnet_id == "" ? 1 : 0
  name       = "${var.naming_prefix}hostnet"
  network_id = var.hostnet_network_id != "" ? var.hostnet_network_id : openstack_networking_network_v2.hostnet[0].id
  cidr       = var.hostnet_cidr
  ip_version = 4

  dns_nameservers = var.dns_nameservers

  dynamic "allocation_pool" {
    for_each = var.allocation_pool_start != null ? [1] : []
    content {
      start = var.allocation_pool_start
      end   = var.allocation_pool_end
    }
  }
}

resource "openstack_networking_router_v2" "hostnet" {
  name                = "${var.naming_prefix}hostnet"
  external_network_id = var.router_external_network_id
}

resource "openstack_networking_router_interface_v2" "hostnet" {
  router_id = openstack_networking_router_v2.hostnet.id
  subnet_id = local.hostnet_subnet_id
}

###############################################################################
# Mgmt VLAN Network Resources
# (VLAN-tagged management network routed via SVI on the 10-dot backbone)
###############################################################################

data "openstack_networking_subnetpool_v2" "mgmt" {
  name = var.mgmt_subnet_pool
}

resource "openstack_networking_network_v2" "mgmt" {
  name = "${var.naming_prefix}mgmt"

  segments {
    network_type     = "vlan"
    physical_network = var.network_provider
    segmentation_id  = var.mgmt_vlan_id
  }
}

resource "openstack_networking_subnet_v2" "mgmt" {
  name          = "${var.naming_prefix}mgmt"
  network_id    = openstack_networking_network_v2.mgmt.id
  subnetpool_id = data.openstack_networking_subnetpool_v2.mgmt.id
  prefix_length = var.mgmt_prefix_length
  ip_version    = 4
  enable_dhcp   = false
}

resource "openstack_networking_router_v2" "mgmt_svi" {
  name = "${var.naming_prefix}mgmt-svi"

  value_specs = {
    "flavor_id" = "svi"
  }
}

resource "openstack_networking_router_interface_v2" "mgmt_svi" {
  router_id = openstack_networking_router_v2.mgmt_svi.id
  subnet_id = openstack_networking_subnet_v2.mgmt.id
}

###############################################################################
# MetalLB VLAN Network Resources
# (One or more VLAN-tagged networks for MetalLB public IP pools)
###############################################################################

data "openstack_networking_subnetpool_v2" "metallb" {
  for_each = local.metallb_map

  name = each.value.subnet_pool
}

resource "openstack_networking_network_v2" "metallb" {
  for_each = local.metallb_map

  name = "${var.naming_prefix}${each.key}"

  segments {
    network_type     = "vlan"
    physical_network = var.network_provider
    segmentation_id  = each.value.vlan_id
  }
}

resource "openstack_networking_subnet_v2" "metallb" {
  for_each = local.metallb_map

  name          = "${var.naming_prefix}${each.key}"
  network_id    = openstack_networking_network_v2.metallb[each.key].id
  subnetpool_id = data.openstack_networking_subnetpool_v2.metallb[each.key].id
  ip_version    = 4
}

resource "openstack_networking_router_v2" "metallb_svi" {
  for_each = local.metallb_map

  name = "${var.naming_prefix}${each.key}-svi"

  value_specs = {
    "flavor_id" = "svi"
  }
}

resource "openstack_networking_router_interface_v2" "metallb_svi" {
  for_each = local.metallb_map

  router_id = openstack_networking_router_v2.metallb_svi[each.key].id
  subnet_id = openstack_networking_subnet_v2.metallb[each.key].id
}

###############################################################################
# Locals — Resolved IDs and Computed Values
###############################################################################

locals {
  # Resolved hostnet IDs (use pre-existing if provided, else newly created)
  hostnet_network_id = var.hostnet_network_id != "" ? var.hostnet_network_id : openstack_networking_network_v2.hostnet[0].id
  hostnet_subnet_id  = var.hostnet_subnet_id != "" ? var.hostnet_subnet_id : openstack_networking_subnet_v2.hostnet[0].id

  # Mgmt subnet CIDR (dynamically allocated from pool)
  mgmt_subnet_cidr = openstack_networking_subnet_v2.mgmt.cidr

  # MetalLB network map for for_each
  metallb_map = { for net in var.metallb_networks : net.pool_name => net }
}
