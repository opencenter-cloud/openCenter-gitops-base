data "cloudinit_config" "undercloud_ubuntu24" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/undercloud-ubuntu24-init.tpl", {
      mgmt_vlan_id        = var.mgmt_vlan_id
      mgmt_svi_gateway    = cidrhost(openstack_networking_subnet_v2.mgmt.cidr, 1)
      mgmt_subnet_cidr    = openstack_networking_subnet_v2.mgmt.cidr
      metallb_networks    = var.metallb_networks
      ssh_authorized_keys = var.ssh_authorized_keys
      ntp_servers         = var.ntp_servers
      ca_certificates     = join("\n", compact([var.openstack_ca, (var.services_ca_enabled ? module.ca[0].certificate : ""), var.ca_certificates]))
    })
  }
}
