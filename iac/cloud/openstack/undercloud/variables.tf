###############################################################################
# OpenStack Authentication Variables
# (Matching openstack-nova module types and semantics)
###############################################################################

variable "openstack_auth_url" {
  type = string
}

variable "openstack_user_name" {
  type = string
}

variable "openstack_password" {
  type = string
}

variable "openstack_tenant_name" {
  type = string
}

variable "openstack_region" {
  type    = string
  default = "RegionOne"
}

variable "openstack_project_domain_name" {
  type    = string
  default = null
}

variable "openstack_user_domain_name" {
  type    = string
  default = null
}

variable "openstack_insecure" {
  type    = bool
  default = false
}

variable "openstack_ca" {
  type = string
}

variable "application_credential_id" {
  type    = string
  default = ""
}

variable "application_credential_secret" {
  type    = string
  default = ""
}

###############################################################################
# Shared Variables
# (Matching openstack-nova module types and semantics)
###############################################################################

variable "naming_prefix" {
  type = string
}

variable "availability_zone" {
  type    = string
  default = "nova"
}

variable "image_id" {
  type = string
}

variable "ssh_authorized_keys" {
  type = list(string)
}

variable "dns_nameservers" {
  type = list(string)
  default = [
    "8.8.8.8",
    "8.8.4.4",
  ]
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ntp_servers" {
  type = list(string)
  default = [
    "time.dfw1.rackspace.com",
    "time2.dfw1.rackspace.com",
  ]
}

###############################################################################
# Cluster Sizing
###############################################################################

variable "size_master" {
  type = object({
    count  = number
    flavor = string
  })
}

variable "size_worker" {
  type = object({
    count  = number
    flavor = string
  })
}

###############################################################################
# Kubernetes Networking
###############################################################################

variable "subnet_pods" {
  type    = string
  default = "10.42.0.0/16"
}

variable "subnet_services" {
  type    = string
  default = "10.43.0.0/16"
}

variable "k8s_api_port" {
  type    = number
  default = 443
}

variable "k8s_api_port_acl" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks to allow access to the K8s API Port"
}

###############################################################################
# Undercloud-Specific Variables
###############################################################################

variable "hostnet_cidr" {
  type        = string
  default     = "172.31.20.0/24"
  description = "CIDR for the hostnet subnet"
}

variable "hostnet_network_id" {
  type        = string
  default     = ""
  description = "Pre-existing hostnet network ID. Empty = create new."
}

variable "hostnet_subnet_id" {
  type        = string
  default     = ""
  description = "Pre-existing hostnet subnet ID. Empty = create new."
}

variable "mgmt_vlan_id" {
  type        = number
  default     = 102
  description = "VLAN ID for management network (1-4094)"
  validation {
    condition     = var.mgmt_vlan_id >= 1 && var.mgmt_vlan_id <= 4094
    error_message = "mgmt_vlan_id must be between 1 and 4094."
  }
}

variable "mgmt_subnet_pool" {
  type        = string
  description = "Neutron subnet pool name for mgmt network CIDR allocation"
}

variable "mgmt_prefix_length" {
  type        = number
  default     = 26
  description = "Prefix length for mgmt subnet allocation from pool"
}

variable "network_provider" {
  type        = string
  default     = "datacentre"
  description = "Physical network name for provider VLAN segments (only used if provider network creation is needed)"
}

variable "router_flavor" {
  type        = string
  default     = ""
  description = "Neutron router flavor (e.g. 'svi'). Empty = use default router flavor."
}

variable "metallb_networks" {
  type = list(object({
    pool_name   = string
    vlan_id     = optional(number, 105)
    subnet_pool = string
  }))
  default     = []
  description = "List of MetalLB VLAN network configurations"
  validation {
    condition = alltrue([
      for net in var.metallb_networks : net.vlan_id >= 1 && net.vlan_id <= 4094
    ])
    error_message = "All metallb_networks entries must have vlan_id between 1 and 4094."
  }
}

variable "kube_vip_address" {
  type        = string
  default     = ""
  description = "Fixed IP for kube-vip VIP. Empty = broadcast-1 of mgmt subnet."
}

variable "disable_bastion" {
  type        = bool
  default     = true
  description = "Disable bastion host creation. Default true for undercloud (SVI-routed access)."
}

###############################################################################
# Boot-from-Volume Variables — Master Nodes
###############################################################################

variable "master_node_bfv_source_type" {
  type        = string
  default     = "image"
  description = "The source type of the device. Must be one of blank, image, volume, or snapshot."
}

variable "master_node_bfv_volume_size" {
  type        = number
  default     = 0
  description = "Boot from volume size for the master nodes"
}

variable "master_node_bfv_destination_type" {
  type        = string
  default     = "local"
  description = "Boot from volume type for the master nodes"
}

variable "master_node_bfv_delete_on_termination" {
  type        = bool
  default     = true
  description = "If true, the volume will be deleted when the server is terminated."
}

variable "master_node_bfv_volume_type" {
  type        = string
  default     = "Standard"
  description = "The volume type that will be used, for example SSD or HDD storage."
}

###############################################################################
# Boot-from-Volume Variables — Worker Nodes
###############################################################################

variable "worker_node_bfv_source_type" {
  type        = string
  default     = "image"
  description = "The source type of the device. Must be one of blank, image, volume, or snapshot."
}

variable "worker_node_bfv_volume_size" {
  type        = number
  default     = 0
  description = "Boot from volume size for the worker nodes"
}

variable "worker_node_bfv_destination_type" {
  type        = string
  default     = "local"
  description = "Boot from volume type for the worker nodes"
}

variable "worker_node_bfv_delete_on_termination" {
  type        = bool
  default     = true
  description = "If true, the volume will be deleted when the server is terminated."
}

variable "worker_node_bfv_volume_type" {
  type        = string
  default     = "standard"
  description = "The volume type that will be used, for example SSD or HDD storage."
}

###############################################################################
# Additional Block Devices
###############################################################################

variable "additional_block_devices_master" {
  description = "List of additional block devices to attach to master instances"
  type = list(object({
    source_type           = string
    volume_size           = number
    volume_type           = optional(string, "")
    boot_index            = number
    destination_type      = optional(string, "volume")
    delete_on_termination = optional(bool, true)
    mountpoint            = string
    filesystem            = optional(string, "ext4")
    label                 = string
  }))
  default = []
}

variable "additional_block_devices_worker" {
  description = "List of additional block devices to attach to worker instances"
  type = list(object({
    source_type           = string
    volume_size           = number
    volume_type           = optional(string, "")
    boot_index            = number
    destination_type      = optional(string, "volume")
    delete_on_termination = optional(bool, true)
    mountpoint            = string
    filesystem            = optional(string, "ext4")
    label                 = string
  }))
  default = []
}

###############################################################################
# Server Group Affinity
###############################################################################

variable "cp_server_group_affinity" {
  type        = list(string)
  default     = ["anti-affinity"]
  description = "Set the Affinity Policy for the control plane server group"
}

variable "wn_server_group_affinity" {
  type        = list(string)
  default     = []
  description = "Set the Affinity Policy for the worker server group"
}

###############################################################################
# Additional Worker Pools
###############################################################################

variable "additional_server_pools_worker" {
  description = "List of additional worker server pools with their configurations"
  type = list(object({
    name                                  = string
    server_group_affinity                 = optional(string, "soft-anti-affinity")
    worker_count                          = number
    flavor_worker                         = string
    node_worker                           = string
    image_id                              = string
    worker_node_bfv_volume_size           = optional(number, 0)
    worker_node_bfv_destination_type      = optional(string, "local")
    worker_node_bfv_source_type           = optional(string, "image")
    worker_node_bfv_volume_type           = optional(string, "")
    worker_node_bfv_delete_on_termination = optional(bool, true)
    additional_block_devices_worker = optional(list(object({
      source_type           = string
      volume_size           = number
      volume_type           = string
      boot_index            = number
      destination_type      = string
      delete_on_termination = bool
      mountpoint            = optional(string, "")
      filesystem            = optional(string, "")
      label                 = optional(string, "")
    })), [])
  }))
  default = []
}

###############################################################################
# Node Naming Prefix Variables
###############################################################################

variable "node_master" {
  type        = string
  default     = ""
  description = "Define the role to be used in hostname for master nodes"
}

variable "node_worker" {
  type        = string
  default     = ""
  description = "Define the role to be used in hostname for worker nodes"
}

###############################################################################
# Router and Floating IP
###############################################################################

variable "router_external_network_id" {
  type = string
}

variable "floatingip_pool" {
  type    = string
  default = ""
}

variable "allocation_pool_start" {
  type    = string
  default = null
}

variable "allocation_pool_end" {
  type    = string
  default = null
}

###############################################################################
# Bastion Variables
###############################################################################

variable "flavor_bastion" {
  type        = string
  default     = "gp.0.2.4"
  description = "Flavor for the bastion host instance"
}

variable "image_name" {
  type        = string
  default     = ""
  description = "Image name for bastion host (used alongside image_id)"
}

variable "pkg_manager_proxy" {
  type        = string
  default     = ""
  description = "HTTP proxy URL for the package manager"
}

###############################################################################
# CA-Related Variables
###############################################################################

variable "services_ca_enabled" {
  type    = bool
  default = false
}

variable "services_ca_crt" {
  type    = string
  default = ""
}

variable "services_ca_key" {
  type    = string
  default = ""
}

variable "ca_certificates" {
  type    = string
  default = ""
}
