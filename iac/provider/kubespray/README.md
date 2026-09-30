# Kubespray

| Key | Type | Default| Description |
| --- | --- | --- | --- |
| address_bastion | string | "" | Public IP address of the bastion host for SSH access |
| additional_sysctl | list(object({ name = string, value = string })) | [] | Additional sysctl settings applied by Kubespray on all nodes |
| baremetal_deployment | bool | false | No bastion will be used in inventory and it wont wait for cloud-init to complete |
| cert_manager_enabled | bool | false | Enable the built-in cert-manager in Kubespray |
| cluster_name | string | "" | Name of the Kubernetes cluster |
| cni_iface | string | "eth0" | Network interface for CNI plugin ("eth0") |
| deploy_cluster | bool | false | Whether to run the Kubespray playbooks and create the Kubernetes cluster (true). When false, the module is infrastructure-only: it renders inventory and group variables but performs no SSH, Ansible, Kubespray, cloud-init, hardening, or kubeconfig execution. |
| cloudinit_wait_timeout_seconds | number | 600 | Positive per-host deadline for `cloud-init status --wait`; timed-out and failed waits emit Ansible diagnostics and preserve the original failure. |
| dns_zone_name | string | "" | DNS name for the Kubernetes API ("k8s.cluster-name.demo.mk8s.net") |
| coredns_external_zones | list(object({ zones = list(string), nameservers = list(string), cache = number })) | [] | External DNS zones forwarded by CoreDNS to the specified nameservers |
| master_nodes | list(object) | List of objects with id, name and access_ip_v4 | Configuration object for master nodes |
| network_plugin | string | "none" | CNI network plugin to use ("calico"). Set to "none" to deploy the CNI separately |
| kubeconfig_path | string | "./kubeconfig.yaml" | Local path for the fetched kubeconfig when `deploy_cluster` is true |
| k8s_hardening_enabled | bool | false | Enable Kubernetes security hardening. Will include additional hardening manifest. |
| os_hardening_enabled | bool | false | Enable OS security hardening. Will run ansible-hardening playbook on the ansible group k8s_cluster |
| ssh_user | string | "ubuntu" | SSH username for node access |
| subnet_nodes | string | "" | CIDR for node network servers|
| subnet_pods | string | "10.42.0.0/16" | CIDR for pod network |
| subnet_services | string | "10.43.0.0/16" | CIDR for service network |
| sysctl_file_path | string | "" | Optional sysctl configuration file path; when empty Kubespray uses its default |
| sysctl_ignore_unknown_keys | bool | null | Whether Kubespray ignores unknown sysctl keys; null omits the setting |
| kubernetes_version | string | "1.30.4" | Kubernetes version to deploy  |
| kubespray_version | string | "v2.28.1" | Kubespray version to use |
| kube_vip_enabled | bool | false | Enable kube-vip for HA on Kube API Server. Requires vrrp_enabled to true  |
| kube_pod_security_exemptions_namespaces | list(string) | [] | Namespaces exempt from pod security |
| worker_nodes | list(object) | List of objects with id, name and access_ip_v4 | Configuration object for worker nodes |
| k8s_api_ip | string | "" | External IP for Kubernetes API |
| k8s_api_port | number | 6443 | Port for Kubernetes API |
| vrrp_ip | string | "" | VRRP IP for high availability. Used for kube-vip and the internal IP of Octavia LB. Nodes will look for this IP when making requests to Kubernetes API server. |
| vrrp_enabled | bool | "false" | Enable the use of the vrrp_ip port without Octavia. |
| windows_nodes | list(object) | List of objects with id, name and access_ip_v4 | Configuration object for Windows worker nodes |
| use_octavia | bool | false | Use Octavia load balancer. Cannot be used if vrrp_enabled and kube_vip_enabled  |
| kube_oidc_auth_enabled | bool | false | Enable OIDC authentication |
| kube_oidc_url | string | "" | OIDC provider URL |
| kube_oidc_client_id | string | "kubernetes" | OIDC client ID |
| kube_oidc_ca_file | string | "/etc/kubernetes/ssl/ca.pem" | CA file for OIDC provider |
| kube_oidc_username_claim | string | "sub" | JWT claim for username |
| kube_oidc_username_prefix | string | 'oidc:' | Prefix for OIDC usernames |
| kube_oidc_groups_claim | string | "groups" | JWT claim for groups |
| kube_oidc_groups_prefix | string | 'oidc:' | Prefix for OIDC groups |

## Repository implementation

- Source path: `iac/provider/kubespray/`.
- `main.tf` renders the Kubespray inventory and group variables from the supplied node objects and can optionally run the Kubespray playbooks when `deploy_cluster` is enabled; `hosts.tpl` is the inventory template and `variables.tf` is the input contract.
- The default CNI is `none`; a separate CNI module or service deployment must be selected when the cluster requires networking.
- `deploy_cluster = false` is the safe infrastructure-only mode. Its exact guarantee is that it performs no remote or kubeconfig execution while inventory outputs remain available. It still generates the inventory and local group-variable files, but all remote execution resources (including OS hardening, cloud-init waiting, Kubespray, and kubeconfig retrieval) are disabled. Inventory generation alone does not contact nodes.
- With `deploy_cluster = true`, cloud-init waits are bounded per host by `cloudinit_wait_timeout_seconds`. Exit codes 0 and 2 remain successful; unreachable hosts retain the existing retry behavior. Other failures and exhausted retries trigger per-host Ansible ping, hostname, cloud-init status, `cloud-init analyze blame`, and cloud-init journal diagnostics, then return the original failure code.
- Stable outputs include `lifecycle_contract_version` (`1`), `inventory_path`, `deployment_enabled`, `deployment_mode`, API address/port, and node metadata. `kubeconfig_path` is `null` unless deployment is enabled.

## Migration

Consumers that only need rendered inventory should explicitly use `deploy_cluster = false` (the default); no remote prerequisites are required in that mode. Consumers that previously relied on an unconditional hardening or kubeconfig side effect must set `deploy_cluster = true`. Read the `deployment_mode` and `kubeconfig_path` outputs rather than assuming a kubeconfig was created.

## Validation and limitations

From this directory, run `terraform fmt -check` and `terraform validate` after `terraform init` with the required provider credentials/configuration available. The module requires reachable nodes, SSH access, compatible OS images, and cloud/provider outputs from a consuming root; validation alone does not deploy a cluster. Review mutually exclusive VIP/Octavia settings and OIDC credentials before apply.
