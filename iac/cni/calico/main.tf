locals {
  calico_interface_autodetect      = lower(trimspace(var.calico_interface_autodetect))
  calico_interface                 = trimspace(var.cni_iface)
  calico_interface_autodetect_cidr = trimspace(var.calico_interface_autodetect_cidr)

  calico_values = templatefile("${path.module}/calico-values.tpl", {
    cni_iface                           = local.calico_interface
    subnet_pods                         = var.subnet_pods
    subnet_services                     = var.subnet_services
    windows_dataplane                   = var.windows_dataplane
    calico_nat_outgoing                 = var.calico_nat_outgoing == true ? "Enabled" : "Disabled"
    calico_encapsulation_type           = var.calico_encapsulation_type
    calico_interface_autodetect         = local.calico_interface_autodetect
    calico_interface_autodetect_cidr    = local.calico_interface_autodetect_cidr
    calico_version                      = var.calico_version
    k8s_internal_ip                     = var.k8s_internal_ip
    k8s_api_port                        = var.k8s_api_port
    kubernetes_service_endpoint_enabled = var.kubernetes_service_endpoint_enabled
  })

  calico_autodetection = {
    mode        = local.calico_interface_autodetect
    interface   = local.calico_interface_autodetect == "interface" ? local.calico_interface : null
    cidr        = local.calico_interface_autodetect == "cidr" ? local.calico_interface_autodetect_cidr : null
    first_found = local.calico_interface_autodetect == "first-found"
  }
}

output "calico_values" {
  description = "Rendered Calico Helm values for the GitOps generator."
  value       = local.calico_values

  precondition {
    condition     = local.calico_interface_autodetect != "interface" || local.calico_interface != ""
    error_message = "cni_iface must be nonblank when calico_interface_autodetect is interface."
  }

  precondition {
    condition     = local.calico_interface_autodetect != "cidr" || local.calico_interface_autodetect_cidr != ""
    error_message = "calico_interface_autodetect_cidr must be nonblank when calico_interface_autodetect is cidr."
  }
}

output "calico_autodetection" {
  description = "Selected Calico node address autodetection settings."
  value       = local.calico_autodetection
}
