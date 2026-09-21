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

variable "trunk_admin_state_up" {
  type        = bool
  default     = true
  nullable    = false
  description = "Administrative up/down state applied to all OpenStack trunk resources"
}

variable "trunk_interface_name" {
  type        = string
  default     = "eno3np0"
  nullable    = false
  description = "Predictable Linux interface name assigned to the OpenStack trunk parent"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+$", var.trunk_interface_name)) && length(var.trunk_interface_name) <= 15
    error_message = "trunk_interface_name may contain only letters, numbers, underscores, periods, and hyphens and must not exceed 15 characters."
  }
}

variable "trunk_mtu" {
  type        = number
  default     = 9000
  nullable    = false
  description = "MTU configured on the trunk parent and all management and MetalLB VLAN interfaces"

  validation {
    condition     = var.trunk_mtu >= 1280 && var.trunk_mtu <= 9216 && floor(var.trunk_mtu) == var.trunk_mtu
    error_message = "trunk_mtu must be an integer between 1280 and 9216."
  }
}

variable "mgmt_vlan_id" {
  type        = number
  default     = 102
  description = "VLAN ID and dedicated policy-route table for the management network"

  validation {
    condition     = var.mgmt_vlan_id >= 1 && var.mgmt_vlan_id <= 4094 && floor(var.mgmt_vlan_id) == var.mgmt_vlan_id && !contains([253, 254, 255], var.mgmt_vlan_id)
    error_message = "mgmt_vlan_id must be an integer between 1 and 4094 and must not use reserved route tables 253, 254, or 255."
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
    pool_name             = string
    vlan_id               = optional(number, 105)
    subnet_pool           = string
    interface_name        = optional(string)
    table_id              = optional(number)
    rule_priority         = optional(number)
    allowed_address_pairs = optional(list(string), [])
  }))
  default     = []
  description = "MetalLB VLAN networks and first-boot policy-routing configuration"

  validation {
    condition = alltrue([
      for net in var.metallb_networks : net.vlan_id >= 1 && net.vlan_id <= 4094 && floor(net.vlan_id) == net.vlan_id
    ])
    error_message = "All metallb_networks entries must have an integer vlan_id between 1 and 4094."
  }

  validation {
    condition = alltrue([
      for net in var.metallb_networks :
      can(regex("^[A-Za-z0-9_-]+$", net.pool_name)) &&
      can(regex("^[A-Za-z0-9_.-]+$", net.interface_name != null ? net.interface_name : "metal.${net.vlan_id}")) &&
      length(net.interface_name != null ? net.interface_name : "metal.${net.vlan_id}") <= 15
    ])
    error_message = "MetalLB pool names and interface names may contain only letters, numbers, underscores, periods, and hyphens; interface names must not exceed 15 characters."
  }

  validation {
    condition = alltrue([
      for net in var.metallb_networks :
      (net.table_id != null ? net.table_id : net.vlan_id) > 0 &&
      floor(net.table_id != null ? net.table_id : net.vlan_id) == (net.table_id != null ? net.table_id : net.vlan_id) &&
      !contains([253, 254, 255], net.table_id != null ? net.table_id : net.vlan_id)
    ])
    error_message = "MetalLB route table IDs must be positive integers and must not use reserved tables 253, 254, or 255."
  }

  validation {
    condition = alltrue([
      for net in var.metallb_networks :
      (net.rule_priority != null ? net.rule_priority : 1000 + net.vlan_id) > 0 &&
      (net.rule_priority != null ? net.rule_priority : 1000 + net.vlan_id) < 32766 &&
      floor(net.rule_priority != null ? net.rule_priority : 1000 + net.vlan_id) == (net.rule_priority != null ? net.rule_priority : 1000 + net.vlan_id)
    ])
    error_message = "MetalLB policy-rule priorities must be integers from 1 through 32765."
  }

  validation {
    condition = alltrue([
      length(distinct([for net in var.metallb_networks : net.pool_name])) == length(var.metallb_networks),
      length(distinct([for net in var.metallb_networks : net.vlan_id])) == length(var.metallb_networks),
      length(distinct([for net in var.metallb_networks : net.interface_name != null ? net.interface_name : "metal.${net.vlan_id}"])) == length(var.metallb_networks),
      length(distinct([for net in var.metallb_networks : net.table_id != null ? net.table_id : net.vlan_id])) == length(var.metallb_networks),
      length(distinct([for net in var.metallb_networks : net.rule_priority != null ? net.rule_priority : 1000 + net.vlan_id])) == length(var.metallb_networks),
    ])
    error_message = "MetalLB pool names, VLAN IDs, interface names, route table IDs, and policy-rule priorities must be unique."
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
