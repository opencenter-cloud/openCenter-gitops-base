provider "openstack" {
  auth_url                      = var.openstack_auth_url
  cacert_file                   = var.openstack_ca
  delayed_auth                  = true
  insecure                      = var.openstack_insecure
  region                        = var.openstack_region
  use_octavia                   = false

  # When using application credentials, username/password and project scoping
  # must be null — app creds carry their own scope. Passing conflicting values
  # causes Keystone to reject the auth request.
  user_name                     = var.application_credential_id != "" ? null : var.openstack_user_name
  password                      = var.application_credential_id != "" ? null : var.openstack_password
  tenant_name                   = var.application_credential_id != "" ? null : var.openstack_tenant_name
  user_domain_name              = var.application_credential_id != "" ? null : var.openstack_user_domain_name
  project_domain_name           = var.application_credential_id != "" ? null : var.openstack_project_domain_name

  application_credential_id     = var.application_credential_id
  application_credential_secret = var.application_credential_secret
}
