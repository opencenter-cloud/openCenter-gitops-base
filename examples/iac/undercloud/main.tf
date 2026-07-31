locals {
  # this will be the user's name and the DNS zone prefix
  cluster_name = "sandbox"
  # Prefix to add to Openstack resource names
  naming_prefix                 = "${local.cluster_name}-"
  openstack_auth_url            = "https://keystone.staging.undercloud.rackspace.net/v3"
  openstack_insecure            = false
  openstack_region              = "iad3-staging"
  availability_zone             = "nova"
  openstack_user_name           = ""
  openstack_user_password       = ""
  application_credential_id     = var.os_application_credential_id
  application_credential_secret = var.os_application_credential_secret
  openstack_project_domain_name = "sandbox"
  openstack_user_domain_name    = "sandbox"
  openstack_tenant_name         = "opencenter"
  floatingip_pool               = "PUBLICNET"
  router_external_network_id    = "b420e863-7d26-4c87-8974-76f6c8750640"
  # DNS servers to configure on the nodes
  dns_nameservers  = ["8.8.8.8", "8.8.4.4"]
  ntp_servers      = ["time.iad3.rackspace.com", "time2.iad3.rackspace.com"]
  image_id         = "c189b216-9fa0-405c-a4ba-39c592e98716"
  k8s_api_port     = 443
  k8s_api_port_acl = ["0.0.0.0/0"]
  worker_count     = 2
  # Enter 1 or 3 masters.
  master_count = 3
  ssh_user     = "ubuntu"
  # these are the ssh public keys that will be able to connect to the cluster's bastion node
  ssh_authorized_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZzRbKOJSUa5h4GzGE3zr6g6jEOUBH6+Xlu9sH7CASp 000001-rax-ai-sandbox-dfw3"]
  node_worker         = "wn"
  node_master         = "cp"
  #FLEX Flavor Settings ==========================
  flavor_bastion = "gp2.small"
  flavor_master  = "gp2.small"
  flavor_worker  = "gp2.medium"

  # ===================================
  # Undercloud-specific settings (multi-VLAN trunk-port topology)
  hostnet_cidr         = "10.2.128.0/24"
  trunk_interface_name = "eno3np0"
  trunk_mtu            = 9000
  mgmt_vlan_id         = 109
  mgmt_subnet_pool     = "public-tendot-ip4"
  kube_vip_address     = ""
  disable_bastion      = true

  # MetalLB public IP network. Terraform configures the tagged interface,
  # policy routes, and pool-CIDR port security on every node at first boot.
  metallb_networks = [
    {
      pool_name   = "public-pool"
      vlan_id     = 105
      subnet_pool = "PUBLIC-IP-POOL"

      # Optional route overrides (defaults shown):
      # interface_name = "metal.105"
      # table_id       = 105
      # rule_priority  = 1105

      # Optional extra addresses/CIDRs. The allocated pool CIDR is always
      # added automatically to every MetalLB subport.
      allowed_address_pairs = [
        # "192.0.2.10",
      ]
    }
  ]

  # ===================================
  #CIDR that will be used by kubernetes pods. Not an openstack network.
  subnet_pods = "10.42.0.0/16"
  #CIDR that will be used for kubernetes services. Not an openstack network.
  subnet_services = "10.43.0.0/16"

  # ===================================
  #ca_certificates add CA certificates to server's trusts. Good for trusting internal private Certificate Authorities.
  ca_certificates = ""
  openstack_ca    = ""

  cp_server_group_affinity = ["soft-anti-affinity"]

  # ====================================
  #Kubespray Settings
  kubespray_version  = "v2.31.0"
  kubernetes_version = "1.35.4"
  # CNI install_method: "helm" (default) and "kustomize-helm" skip CNI in Kubespray.
  # OpenStack deploy installs the selected CNI after kubeconfig normalization.
  # "kubespray" is retained only for non-OpenStack migration compatibility.
  network_plugin = "calico"
  deploy_cluster = true
  dns_zone_name  = "sandbox.iad3.k8s.opencenter.cloud"
  #kub-vip settings
  kube_vip_enabled = true
  #Hardening
  k8s_hardening_enabled                   = true
  kube_pod_security_exemptions_namespaces = ["trivy-temp"]
  # Must remain false for the initial bootstrap. No CNI is installed by Kubespray
  # (CNI is deployed via GitOps after kubeconfig normalization). Kubelet certificate
  # rotation requires node Ready status, which depends on a functioning CNI.
  # Enabling this before the CNI is running causes bootstrap failure.
  kubelet_rotate_server_certificates = false
  os_hardening_enabled               = true

  #Calico Settings
  cni_iface = "mgmt.109"
  #Interface detection method for Calico nodeAddressAutodetectionV4. Can be "first-found", "interface", "cidr"
  #https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io%2fv1.NodeAddressAutodetection
  calico_interface_autodetect      = "interface"
  calico_interface_autodetect_cidr = ""
  calico_encapsulation_type        = "VXLAN"
  calico_nat_outgoing              = true
  # Hostnet subnet nodes CIDR (used by kubespray and calico for node addressing)
  subnet_nodes = "10.2.128.0/24"
}
module "undercloud" {
  source = "github.com/opencenter-cloud/openCenter-gitops-base.git//iac/cloud/openstack/undercloud?ref=undercloud"

  # OpenStack Authentication
  openstack_auth_url            = local.openstack_auth_url
  openstack_insecure            = local.openstack_insecure
  openstack_region              = local.openstack_region
  openstack_user_name           = local.openstack_user_name
  openstack_password            = local.openstack_user_password
  openstack_tenant_name         = local.openstack_tenant_name
  openstack_project_domain_name = local.openstack_project_domain_name
  openstack_user_domain_name    = local.openstack_user_domain_name
  application_credential_id     = local.application_credential_id
  application_credential_secret = local.application_credential_secret
  openstack_ca                  = local.openstack_ca

  # Naming and placement
  naming_prefix       = local.naming_prefix
  availability_zone   = local.availability_zone
  image_id            = local.image_id
  ssh_user            = local.ssh_user
  ssh_authorized_keys = local.ssh_authorized_keys
  dns_nameservers     = local.dns_nameservers
  ntp_servers         = local.ntp_servers
  node_master         = local.node_master
  node_worker         = local.node_worker

  # Cluster sizing
  size_master = {
    count  = local.master_count
    flavor = local.flavor_master
  }
  size_worker = {
    count  = local.worker_count
    flavor = local.flavor_worker
  }

  # Kubernetes networking
  subnet_pods      = local.subnet_pods
  subnet_services  = local.subnet_services
  k8s_api_port     = local.k8s_api_port
  k8s_api_port_acl = local.k8s_api_port_acl

  # Router and floating IP
  router_external_network_id = local.router_external_network_id
  floatingip_pool            = local.floatingip_pool

  # Undercloud-specific: Physical trunk and management VLAN
  trunk_interface_name = local.trunk_interface_name
  trunk_mtu            = local.trunk_mtu
  mgmt_vlan_id         = local.mgmt_vlan_id
  mgmt_subnet_pool     = local.mgmt_subnet_pool

  # Undercloud-specific: MetalLB networks
  metallb_networks = local.metallb_networks

  # Undercloud-specific: Hostnet
  hostnet_cidr = local.hostnet_cidr

  # Undercloud-specific: kube-vip VIP
  kube_vip_address = local.kube_vip_address

  # Router flavor (UUID of the SVI flavor on this undercloud)
  router_flavor = "031643e2-aa03-4db0-a48a-afaafc2b882d"

  # Bastion and server groups
  disable_bastion          = local.disable_bastion
  flavor_bastion           = local.flavor_bastion
  cp_server_group_affinity = local.cp_server_group_affinity

  # CA certificates
  ca_certificates = local.ca_certificates
}

module "kubespray-cluster" {
  source = "github.com/opencenter-cloud/openCenter-gitops-base.git//iac/provider/kubespray?ref=undercloud"

  address_bastion                         = module.undercloud.master_nodes[1].access_ip_v4
  cluster_name                            = local.cluster_name
  cni_iface                               = local.cni_iface
  deploy_cluster                          = local.deploy_cluster
  dns_zone_name                           = local.dns_zone_name
  master_nodes                            = module.undercloud.master_nodes
  network_plugin                          = local.network_plugin
  k8s_hardening_enabled                   = local.k8s_hardening_enabled
  os_hardening_enabled                    = local.os_hardening_enabled
  ssh_user                                = local.ssh_user
  subnet_nodes                            = local.subnet_nodes
  subnet_pods                             = local.subnet_pods
  subnet_services                         = local.subnet_services
  kubernetes_version                      = local.kubernetes_version
  kubespray_version                       = local.kubespray_version
  kube_vip_enabled                        = local.kube_vip_enabled
  kube_pod_security_exemptions_namespaces = local.kube_pod_security_exemptions_namespaces
  kubelet_rotate_server_certificates      = local.kubelet_rotate_server_certificates
  worker_nodes                            = module.undercloud.worker_nodes
  k8s_api_ip                              = module.undercloud.k8s_api_ip
  k8s_internal_ip                         = module.undercloud.k8s_internal_ip
  k8s_api_port                            = local.k8s_api_port
  vrrp_ip                                 = module.undercloud.k8s_api_ip
  vrrp_enabled                            = true
  windows_nodes                           = []
  use_octavia                             = false
  containerd_cri_extra_settings = {
    cdi_spec_dirs = ["/etc/cdi", "/var/run/cdi"]
  }
}
module "calico" {
  source = "github.com/opencenter-cloud/openCenter-gitops-base.git//iac/cni/calico?ref=main"

  calico_interface_autodetect      = local.calico_interface_autodetect
  calico_encapsulation_type        = local.calico_encapsulation_type
  calico_nat_outgoing              = local.calico_nat_outgoing
  calico_interface_autodetect_cidr = local.calico_interface_autodetect_cidr == "" ? local.subnet_nodes : local.calico_interface_autodetect_cidr
  cni_iface                        = local.cni_iface
  cluster_name                     = local.cluster_name
  deploy_cluster                   = local.deploy_cluster
  k8s_internal_ip                  = module.undercloud.k8s_internal_ip
  k8s_api_port                     = local.k8s_api_port
  subnet_nodes                     = local.subnet_nodes
  subnet_pods                      = local.subnet_pods
  subnet_services                  = local.subnet_services
  windows_dataplane                = "Disabled"
}
