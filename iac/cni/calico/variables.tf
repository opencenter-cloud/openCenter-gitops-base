variable "deploy_cluster" {
  type    = bool
  default = false
}

variable "calico_nat_outgoing" {
  type    = bool
  default = true
}

variable "calico_interface_autodetect" {
  type    = string
  default = "first-found"

  validation {
    condition = contains(
      ["first-found", "interface", "cidr"],
      lower(trimspace(var.calico_interface_autodetect)),
    )
    error_message = "calico_interface_autodetect must be one of first-found, interface, or cidr."
  }
}

variable "calico_interface_autodetect_cidr" {
  type    = string
  default = ""

  validation {
    condition = trimspace(var.calico_interface_autodetect_cidr) == "" || (
      can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}/[0-9]{1,2}$", trimspace(var.calico_interface_autodetect_cidr))) &&
      can(cidrhost(trimspace(var.calico_interface_autodetect_cidr), 0))
    )
    error_message = "calico_interface_autodetect_cidr must be blank or a valid IPv4 CIDR."
  }
}

variable "calico_encapsulation_type" {
  type    = string
  default = "VXLAN"
}

variable "calico_version" {
  type    = string
  default = "3.29.4" # adjust as needed
}

variable "chart_name" {
  type    = string
  default = "calico"
}

variable "chart_namespace" {
  type    = string
  default = "tigera-operator"
}

variable "chart_repo" {
  type    = string
  default = "https://docs.tigera.io/calico/charts"
}

variable "cluster_name" {
  type    = string
  default = ""
}

variable "cni_iface" {
  type    = string
  default = ""
}

variable "k8s_api_port" {
  type    = number
  default = 6443
}

variable "k8s_internal_ip" {
  type        = string
  default     = ""
  description = "The host used for Calico's explicit Kubernetes API endpoint, typically the internal kube-apiserver VIP."
}

variable "kubernetes_service_endpoint_enabled" {
  type        = bool
  default     = true
  description = "Whether to render the explicit Kubernetes API endpoint. Defaults to true for backward compatibility; set false to use the in-cluster Kubernetes service."
}

variable "subnet_nodes" {
  type    = string
  default = "10.0.0.0/22"
}

variable "subnet_pods" {
  type    = string
  default = "10.42.0.0/16"
}

variable "subnet_services" {
  type    = string
  default = "10.43.0.0/16"
}

variable "windows_dataplane" {
  type    = string
  default = ""
}
