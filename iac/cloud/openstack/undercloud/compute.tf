###############################################################################
# Compute Instances
# Creates control plane (master) and worker instances attached to trunk ports.
###############################################################################

###############################################################################
# Control Plane Instances
###############################################################################

resource "openstack_compute_instance_v2" "master" {
  count             = local.master_count
  name              = "${var.naming_prefix}${var.node_master}${count.index}"
  flavor_name       = var.size_master.flavor
  image_id          = var.image_id
  availability_zone = var.availability_zone
  user_data         = data.cloudinit_config.undercloud_ubuntu24_master[count.index].rendered
  key_pair          = module.ssh-keypair.keypair.name

  block_device {
    uuid                  = var.master_node_bfv_source_type == "blank" ? "" : var.image_id
    source_type           = var.master_node_bfv_source_type
    destination_type      = var.master_node_bfv_destination_type
    volume_size           = var.master_node_bfv_volume_size
    volume_type           = var.master_node_bfv_destination_type == "local" ? "" : var.master_node_bfv_volume_type
    boot_index            = 0
    delete_on_termination = var.master_node_bfv_delete_on_termination
  }

  dynamic "block_device" {
    for_each = var.additional_block_devices_master
    content {
      uuid                  = block_device.value.source_type == "blank" ? "" : null
      source_type           = block_device.value.source_type
      volume_size           = block_device.value.volume_size
      volume_type           = block_device.value.destination_type == "local" ? "" : block_device.value.volume_type
      boot_index            = block_device.value.boot_index
      destination_type      = block_device.value.destination_type
      delete_on_termination = block_device.value.delete_on_termination
    }
  }

  network {
    port = openstack_networking_trunk_v2.master[count.index].port_id
  }

  scheduler_hints {
    group = module.servergroup_master.id
  }

  depends_on = [
    openstack_networking_trunk_v2.master,
    module.secgroup,
    openstack_networking_port_v2.kube_vip_master,
  ]

  lifecycle {
    ignore_changes = [
      user_data,
      image_id,
    ]
  }
}

###############################################################################
# Worker Instances
###############################################################################

resource "openstack_compute_instance_v2" "worker" {
  count             = local.worker_count
  name              = "${var.naming_prefix}${var.node_worker}${count.index}"
  flavor_name       = var.size_worker.flavor
  image_id          = var.image_id
  availability_zone = var.availability_zone
  user_data         = data.cloudinit_config.undercloud_ubuntu24_worker[count.index].rendered
  key_pair          = module.ssh-keypair.keypair.name

  block_device {
    uuid                  = var.worker_node_bfv_source_type == "blank" ? "" : var.image_id
    source_type           = var.worker_node_bfv_source_type
    destination_type      = var.worker_node_bfv_destination_type
    volume_size           = var.worker_node_bfv_volume_size
    volume_type           = var.worker_node_bfv_destination_type == "local" ? "" : var.worker_node_bfv_volume_type
    boot_index            = 0
    delete_on_termination = var.worker_node_bfv_delete_on_termination
  }

  dynamic "block_device" {
    for_each = var.additional_block_devices_worker
    content {
      uuid                  = block_device.value.source_type == "blank" ? "" : null
      source_type           = block_device.value.source_type
      volume_size           = block_device.value.volume_size
      volume_type           = block_device.value.destination_type == "local" ? "" : block_device.value.volume_type
      boot_index            = block_device.value.boot_index
      destination_type      = block_device.value.destination_type
      delete_on_termination = block_device.value.delete_on_termination
    }
  }

  network {
    port = openstack_networking_trunk_v2.worker[count.index].port_id
  }

  dynamic "scheduler_hints" {
    for_each = length(var.wn_server_group_affinity) > 0 ? [1] : []
    content {
      group = module.servergroup_worker[0].id
    }
  }

  depends_on = [
    openstack_networking_trunk_v2.worker,
    module.secgroup,
  ]

  lifecycle {
    ignore_changes = [
      user_data,
      image_id,
    ]
  }
}

###############################################################################
# Additional Worker Pools
# Each pool in var.additional_server_pools_worker gets its own server group,
# trunk ports (parent, mgmt subport, metallb subports), trunk resources, and
# compute instances.
###############################################################################

# --- Locals: Flatten pool instances and metallb combinations ---

locals {
  additional_pool_instances = flatten([
    for pool in var.additional_server_pools_worker : [
      for idx in range(pool.worker_count) : {
        pool_name                 = pool.name
        instance_idx              = idx
        flavor                    = pool.flavor_worker
        node_worker               = pool.node_worker
        image_id                  = pool.image_id
        bfv_source_type           = pool.worker_node_bfv_source_type
        bfv_destination_type      = pool.worker_node_bfv_destination_type
        bfv_volume_size           = pool.worker_node_bfv_volume_size
        bfv_volume_type           = pool.worker_node_bfv_volume_type
        bfv_delete_on_termination = pool.worker_node_bfv_delete_on_termination
        additional_block_devices  = pool.additional_block_devices_worker
      }
    ]
  ])

  additional_pool_instances_map = { for inst in local.additional_pool_instances : "${inst.pool_name}-${inst.instance_idx}" => inst }

  # Flatten pool × metallb combinations for subport creation
  additional_pool_metallb = flatten([
    for inst in local.additional_pool_instances : [
      for name, net in local.metallb_map : {
        key                   = "${inst.pool_name}-${inst.instance_idx}-${name}"
        pool_name             = inst.pool_name
        inst_idx              = inst.instance_idx
        metallb_name          = name
        network_id            = openstack_networking_network_v2.metallb[name].id
        vlan_id               = net.vlan_id
        allowed_address_pairs = net.allowed_address_pairs
      }
    ]
  ])

  additional_pool_metallb_map = { for p in local.additional_pool_metallb : p.key => p }
}

# --- Server Groups for Additional Pools ---

module "servergroup_additional_worker_pools" {
  source   = "../lib/openstack-servergroup"
  for_each = { for pool in var.additional_server_pools_worker : pool.name => pool }

  naming_prefix         = var.naming_prefix
  name                  = "${each.value.name}-worker"
  server_group_affinity = [each.value.server_group_affinity]
}

# --- Parent Ports for Additional Pools (hostnet, native/untagged) ---

resource "openstack_networking_port_v2" "parent_additional" {
  for_each = local.additional_pool_instances_map

  name       = "${var.naming_prefix}${each.value.node_worker}${each.value.instance_idx}"
  network_id = local.hostnet_network_id

  security_group_ids = [
    module.secgroup.controlplane_id,
    module.secgroup.worker_id,
  ]
}

# --- Mgmt Subports for Additional Pools ---
# Workers do NOT get kube-vip VIP — only pod and service subnet CIDRs

resource "openstack_networking_port_v2" "subport_mgmt_additional" {
  for_each = local.additional_pool_instances_map

  name       = "${var.naming_prefix}${each.value.node_worker}${each.value.instance_idx}-mgmt"
  network_id = openstack_networking_network_v2.mgmt.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.mgmt.id
  }

  allowed_address_pairs {
    ip_address = var.subnet_pods
  }

  allowed_address_pairs {
    ip_address = var.subnet_services
  }

  security_group_ids = [
    module.secgroup.controlplane_id,
    module.secgroup.worker_id,
  ]
}

# --- MetalLB Subports for Additional Pools ---

resource "openstack_networking_port_v2" "subport_metallb_additional" {
  for_each = local.additional_pool_metallb_map

  name        = "${var.naming_prefix}${local.additional_pool_instances_map["${each.value.pool_name}-${each.value.inst_idx}"].node_worker}${each.value.inst_idx}-${each.value.metallb_name}"
  network_id  = each.value.network_id
  no_fixed_ip = true

  # Permit the complete dynamically allocated pool through port security.
  # Neutron uses this subport's MAC when mac_address is omitted.
  dynamic "allowed_address_pairs" {
    for_each = concat(
      [openstack_networking_subnet_v2.metallb[each.value.metallb_name].cidr],
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

# --- Trunk Resources for Additional Pools ---

resource "openstack_networking_trunk_v2" "additional" {
  for_each = local.additional_pool_instances_map

  name    = "${var.naming_prefix}${each.value.node_worker}${each.value.instance_idx}"
  port_id = openstack_networking_port_v2.parent_additional[each.key].id

  sub_port {
    port_id           = openstack_networking_port_v2.subport_mgmt_additional[each.key].id
    segmentation_id   = var.mgmt_vlan_id
    segmentation_type = "vlan"
  }

  dynamic "sub_port" {
    for_each = [for p in local.additional_pool_metallb : p if p.pool_name == each.value.pool_name && p.inst_idx == each.value.instance_idx]
    content {
      port_id           = openstack_networking_port_v2.subport_metallb_additional[sub_port.value.key].id
      segmentation_id   = sub_port.value.vlan_id
      segmentation_type = "vlan"
    }
  }
}

# --- Compute Instances for Additional Pools ---

resource "openstack_compute_instance_v2" "additional_worker" {
  for_each = local.additional_pool_instances_map

  name              = "${var.naming_prefix}${each.value.node_worker}${each.value.instance_idx}"
  flavor_name       = each.value.flavor
  image_id          = each.value.image_id
  availability_zone = var.availability_zone
  user_data         = data.cloudinit_config.undercloud_ubuntu24_additional_worker[each.key].rendered
  key_pair          = module.ssh-keypair.keypair.name

  block_device {
    uuid                  = each.value.bfv_source_type == "blank" ? "" : each.value.image_id
    source_type           = each.value.bfv_source_type
    destination_type      = each.value.bfv_destination_type
    volume_size           = each.value.bfv_volume_size
    volume_type           = each.value.bfv_destination_type == "local" ? "" : each.value.bfv_volume_type
    boot_index            = 0
    delete_on_termination = each.value.bfv_delete_on_termination
  }

  dynamic "block_device" {
    for_each = each.value.additional_block_devices
    content {
      uuid                  = block_device.value.source_type == "blank" ? "" : null
      source_type           = block_device.value.source_type
      volume_size           = block_device.value.volume_size
      volume_type           = block_device.value.destination_type == "local" ? "" : block_device.value.volume_type
      boot_index            = block_device.value.boot_index
      destination_type      = block_device.value.destination_type
      delete_on_termination = block_device.value.delete_on_termination
    }
  }

  network {
    port = openstack_networking_trunk_v2.additional[each.key].port_id
  }

  scheduler_hints {
    group = module.servergroup_additional_worker_pools[each.value.pool_name].id
  }

  depends_on = [
    openstack_networking_trunk_v2.additional,
    module.secgroup,
  ]

  lifecycle {
    ignore_changes = [
      user_data,
      image_id,
    ]
  }
}
