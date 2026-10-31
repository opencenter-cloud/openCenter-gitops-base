output "k8s_api_ip" {
  value = var.use_octavia == true ? module.loadbalancer[0].ip : (var.vrrp_enabled == true ? module.floating-vip[0].ip : module.node_master.nodes[0].access_ip_v4)
}

output "k8s_internal_ip" {
  value = var.vrrp_enabled == false ? (var.use_octavia == true ? var.vrrp_ip : module.node_master.nodes[0].access_ip_v4) : var.vrrp_ip
}

output "bastion_floating_ip" {
  value = var.disable_bastion == true ? "" : module.bastion[0].ip
}

output "worker_nodes" {
  value = module.node_worker.nodes[*]
}

output "master_nodes" {
  value = module.node_master.nodes[*]
}

output "worker_ids" {
  value = module.node_worker.ids
}

output "user-data" {
  value = module.user_data_ubuntu.rendered
}

output "secgroup_id_master" {
  value = module.secgroup.master_id
}

output "windows_nodes" {
  value = var.size_worker_windows.count > 0 ? module.node_worker_windows.nodes[*] : []
}

output "additional_worker_pools_nodes" {
  description = "Map of additional worker pool names to their node objects"
  value = {
    for pool_name, pool_module in module.additional_worker_pools : pool_name => pool_module.nodes[*]
  }
}

output "additional_worker_pools_windows_nodes" {
  description = "Map of additional Windows worker pool names to their node objects"
  value = {
    for pool_name, pool_module in module.additional_worker_pools_windows : pool_name => pool_module.nodes[*]
  }
}

# The cluster network identity as it exists after apply, in both the created and
# the operator-selected case. network/subnet are conditional on vlan_id/subnet_id
# (see network.tf), so neither resource is guaranteed to exist: the effective
# value is the created ID when the resource was made, otherwise the variable the
# caller supplied. The CLI promotes these into
# opencenter.infrastructure.cloud.openstack.networking so the CCM renders a real
# [LoadBalancer] subnet-id instead of a blank one on a tofu-managed network.
output "network_id" {
  description = "ID of the tenant network the cluster runs on: the created network when vlan_id is empty, otherwise the supplied network_id."
  value = var.vlan_id == "" ? (
    length(openstack_networking_network_v2.network) > 0 ?
    openstack_networking_network_v2.network[0].id : var.network_id
  ) : var.network_id
}

output "subnet_id" {
  description = "ID of the node subnet: the created subnet when subnet_id is empty, otherwise the supplied subnet_id."
  value = length(openstack_networking_subnet_v2.subnet) > 0 ? (
    openstack_networking_subnet_v2.subnet[0].id
  ) : var.subnet_id
}