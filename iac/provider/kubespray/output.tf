output "inventory_path" {
  description = "Absolute path to the generated Ansible inventory."
  value       = abspath(local_file.ansible_inventory.filename)
}

output "lifecycle_contract_version" {
  description = "Version of the lifecycle handoff contract exposed by this module."
  value       = 1
}

output "deployment_enabled" {
  description = "Whether remote cluster deployment and its execution resources are enabled."
  value       = var.deploy_cluster
}

output "deployment_mode" {
  description = "Selected module mode."
  value       = var.deploy_cluster ? "cluster-deployment" : "infrastructure-only"
}

output "kubeconfig_path" {
  description = "Absolute kubeconfig path when deployment runs; null in infrastructure-only mode."
  value       = var.deploy_cluster ? abspath(var.kubeconfig_path) : null
}

output "k8s_api_address" {
  description = "Configured Kubernetes API address."
  value       = var.k8s_api_ip
}

output "k8s_api_port" {
  description = "Configured Kubernetes API port."
  value       = var.k8s_api_port
}

output "master_nodes" {
  description = "Control-plane node metadata supplied to the module."
  value       = var.master_nodes
}

output "worker_nodes" {
  description = "Worker node metadata supplied to the module."
  value       = var.worker_nodes
}

output "windows_nodes" {
  description = "Windows node metadata supplied to the module."
  value       = var.windows_nodes
}
