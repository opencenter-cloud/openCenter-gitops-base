###############################################################################
# Module Invocations
# (Security groups, server groups, keypair, bastion, CA, bastion userdata)
###############################################################################

###############################################################################
# Security Groups
###############################################################################

module "secgroup" {
  source = "../lib/openstack-secgroup"

  naming_prefix                          = var.naming_prefix
  subnet_pods                            = var.subnet_pods
  subnet_services                        = var.subnet_services
  subnet_servers                         = ""
  k8s_api_port                           = var.k8s_api_port
  disable_bastion                        = var.disable_bastion
  k8s_api_port_acl                       = var.k8s_api_port_acl
  worker_count_windows                   = 0
  additional_server_pools_worker_windows = []
  vrrp_enabled                           = false
}

###############################################################################
# Server Groups
###############################################################################

module "servergroup_master" {
  source = "../lib/openstack-servergroup"

  name                  = "master"
  naming_prefix         = var.naming_prefix
  server_group_affinity = var.cp_server_group_affinity
}

module "servergroup_worker" {
  source = "../lib/openstack-servergroup"
  count  = length(var.wn_server_group_affinity) > 0 ? 1 : 0

  name                  = "worker"
  naming_prefix         = var.naming_prefix
  server_group_affinity = var.wn_server_group_affinity
}

###############################################################################
# SSH Keypair
###############################################################################

module "ssh-keypair" {
  source = "../lib/openstack-keypair"

  openstack_user_name = var.openstack_user_name
  naming_prefix       = var.naming_prefix
}

###############################################################################
# Bastion Host (conditional — only when disable_bastion = false)
###############################################################################

module "userdata_bastion" {
  source = "../lib/user_data-bastion"
  count  = var.disable_bastion ? 0 : 1

  ca_certificates     = join("\n", compact([var.openstack_ca, (var.services_ca_enabled ? module.ca[0].certificate : ""), var.ca_certificates]))
  ssh_authorized_keys = var.ssh_authorized_keys
  ntp_servers         = var.ntp_servers
  ssh_user            = var.ssh_user
  pkg_manager_proxy   = var.pkg_manager_proxy
}

module "bastion" {
  source = "../lib/openstack-bastion"
  count  = var.disable_bastion ? 0 : 1

  availability_zone   = var.availability_zone
  flavor_bastion      = var.flavor_bastion
  floatingip_pool     = var.floatingip_pool
  image_id            = var.image_id
  image_name          = var.image_name
  naming_prefix       = var.naming_prefix
  network_id          = local.hostnet_network_id
  security_group_name = module.secgroup.controlplane_name
  user_data           = module.userdata_bastion[0].rendered
  key_pair            = module.ssh-keypair.keypair
  module_depends_on   = [openstack_networking_router_interface_v2.hostnet.id]
}

###############################################################################
# CA Certificate Generation (conditional — only when services_ca_enabled)
###############################################################################

module "ca" {
  source = "../lib/ca"
  count  = var.services_ca_enabled ? 1 : 0

  services_ca_crt = var.services_ca_crt
  services_ca_key = var.services_ca_key
}


###############################################################################
# Additional Security Group Rules
# (VRRP, AH, inter-group, K8s API ACL, pod/service CIDRs)
###############################################################################

# VRRP protocol (112) - kube-vip leader election
resource "openstack_networking_secgroup_rule_v2" "master_vrrp" {
  security_group_id = module.secgroup.master_id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "112" # VRRP
}

# AH protocol (51) - kube-vip
resource "openstack_networking_secgroup_rule_v2" "master_ah" {
  security_group_id = module.secgroup.master_id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "51" # AH
}

# Allow all from controlplane group members
resource "openstack_networking_secgroup_rule_v2" "controlplane_from_controlplane" {
  security_group_id = module.secgroup.controlplane_id
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = module.secgroup.controlplane_id
}

# Allow all from worker group members
resource "openstack_networking_secgroup_rule_v2" "controlplane_from_worker" {
  security_group_id = module.secgroup.controlplane_id
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = module.secgroup.worker_id
}

# K8s API port access from ACL CIDRs
resource "openstack_networking_secgroup_rule_v2" "master_k8s_api" {
  count             = length(var.k8s_api_port_acl)
  security_group_id = module.secgroup.master_id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = var.k8s_api_port
  port_range_max    = var.k8s_api_port
  remote_ip_prefix  = var.k8s_api_port_acl[count.index]
}

# Allow all from pod subnet
resource "openstack_networking_secgroup_rule_v2" "controlplane_from_pods" {
  security_group_id = module.secgroup.controlplane_id
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = var.subnet_pods
}

# Allow all from service subnet
resource "openstack_networking_secgroup_rule_v2" "controlplane_from_services" {
  security_group_id = module.secgroup.controlplane_id
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = var.subnet_services
}

# Allow all from mgmt subnet (replaces lib/secgroup controlplane_ipv4_servers)
resource "openstack_networking_secgroup_rule_v2" "controlplane_from_mgmt" {
  security_group_id = module.secgroup.controlplane_id
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = local.mgmt_subnet_cidr
}
