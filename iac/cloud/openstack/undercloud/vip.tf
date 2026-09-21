###############################################################################
# VIP Master Port
# Reserves the kube-vip VIP address on the mgmt subnet before compute
# instances are provisioned, preventing allocation conflicts.
###############################################################################

locals {
  # VIP address: user-specified or broadcast-minus-one of the mgmt subnet
  kube_vip_address = var.kube_vip_address != "" ? var.kube_vip_address : cidrhost(local.mgmt_subnet_cidr, pow(2, 32 - tonumber(split("/", local.mgmt_subnet_cidr)[1])) - 2)
}

resource "openstack_networking_port_v2" "kube_vip_master" {
  name       = "${var.naming_prefix}kube-vip"
  network_id = openstack_networking_network_v2.mgmt.id

  no_security_groups = true

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.mgmt.id
    ip_address = local.kube_vip_address
  }

  depends_on = [
    openstack_networking_subnet_v2.mgmt,
  ]
}
