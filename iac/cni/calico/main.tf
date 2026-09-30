locals {
  calico_values = templatefile("${path.module}/calico-values.tpl", {
    cni_iface                           = var.cni_iface
    subnet_pods                         = var.subnet_pods
    subnet_services                     = var.subnet_services
    windows_dataplane                   = var.windows_dataplane
    calico_nat_outgoing                 = var.calico_nat_outgoing == true ? "Enabled" : "Disabled"
    calico_encapsulation_type           = var.calico_encapsulation_type
    calico_interface_autodetect         = var.calico_interface_autodetect
    calico_interface_autodetect_cidr    = var.calico_interface_autodetect_cidr
    calico_version                      = var.calico_version
    k8s_internal_ip                     = var.k8s_internal_ip
    k8s_api_port                        = var.k8s_api_port
    kubernetes_service_endpoint_enabled = var.kubernetes_service_endpoint_enabled
  })

  calico_autodetection = {
    mode        = var.calico_interface_autodetect
    interface   = var.calico_interface_autodetect == "interface" ? var.cni_iface : null
    cidr        = var.calico_interface_autodetect == "cidr" ? var.calico_interface_autodetect_cidr : null
    first_found = var.calico_interface_autodetect == "first-found"
  }
}

output "calico_values" {
  description = "Rendered Calico Helm values for the GitOps generator."
  value       = local.calico_values
}

output "calico_autodetection" {
  description = "Selected Calico node address autodetection settings."
  value       = local.calico_autodetection
}
