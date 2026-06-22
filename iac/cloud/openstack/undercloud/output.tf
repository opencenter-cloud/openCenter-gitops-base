###############################################################################
# Module Outputs
# Exports key resource identifiers and IP addresses for downstream consumption
# by Terraform modules and Ansible playbooks.
###############################################################################

output "k8s_api_ip" {
  description = "Kube-vip VIP address on mgmt network (no floating IP)"
  value       = openstack_networking_port_v2.kube_vip_master.all_fixed_ips[0]
}

output "k8s_internal_ip" {
  description = "Same as k8s_api_ip (no NAT indirection)"
  value       = openstack_networking_port_v2.kube_vip_master.all_fixed_ips[0]
}

output "master_nodes" {
  description = "Control plane instance objects with mgmt access IPs"
  value = [for i, node in openstack_compute_instance_v2.master : {
    name         = node.name
    id           = node.id
    access_ip_v4 = openstack_networking_port_v2.subport_mgmt_master[i].all_fixed_ips[0]
  }]
}

output "worker_nodes" {
  description = "Worker instance objects with mgmt access IPs"
  value = [for i, node in openstack_compute_instance_v2.worker : {
    name         = node.name
    id           = node.id
    access_ip_v4 = openstack_networking_port_v2.subport_mgmt_worker[i].all_fixed_ips[0]
  }]
}

output "bastion_floating_ip" {
  description = "Bastion public IP (empty if bastion disabled)"
  value       = var.disable_bastion ? "" : module.bastion[0].ip
}

output "mgmt_subnet_cidr" {
  description = "Dynamically allocated mgmt subnet CIDR"
  value       = local.mgmt_subnet_cidr
}

output "mgmt_network_id" {
  description = "Neutron network UUID of mgmt network"
  value       = openstack_networking_network_v2.mgmt.id
}

output "metallb_pools" {
  description = "MetalLB pool information for downstream consumption"
  value = [for name, net in openstack_networking_subnet_v2.metallb : {
    pool_name   = name
    subnet_cidr = net.cidr
    vlan_id     = local.metallb_map[name].vlan_id
  }]
}
