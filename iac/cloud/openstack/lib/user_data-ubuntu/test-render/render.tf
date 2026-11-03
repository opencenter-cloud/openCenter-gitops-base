# Test fixture: renders the module's cloud-config templates as readable text.
# The module itself hands Nova a gzip+base64 MIME payload, which cannot be
# asserted on directly, and Terraform has no gunzip function.
variable "enable_pci_realloc" {
  type    = bool
  default = false
}

variable "reboot" {
  type    = bool
  default = true
}

variable "ub_version" {
  type    = string
  default = ""
}

locals {
  ctx = {
    ca_certificates           = ""
    ssh_user                  = "ubuntu"
    ssh_authorized_keys       = ["ssh-rsa AAAAB3NzaC1yc2E test@example.com"]
    ntp_servers               = ["1.2.3.4", "5.6.7.8"]
    logrotate_keep_old        = 4
    logrotate_size            = "300M"
    filepath                  = "${path.module}/../"
    pf9_onboard               = false
    pf9_account_url           = ""
    pf9_username              = ""
    pf9_password              = ""
    pf9_tenant                = ""
    pf9_region                = ""
    pf9ctl_setup_download_url = "https://pf9ctl.example.invalid"
    reboot                    = var.reboot
    enable_pci_realloc        = var.enable_pci_realloc
  }
}

output "cloud_config" {
  value       = templatefile("${path.module}/../ubuntu-init${var.ub_version}.tpl", local.ctx)
  description = "Rendered cloud-config for the selected Ubuntu template."
}
