---
%{ if kubelet_cloud_provider != "" ~}
# Run kubelet with --cloud-provider=external so an externally deployed cloud
# controller manager (CCM) can initialize each node, set spec.providerID, and
# clear the node.cloudprovider.kubernetes.io/uninitialized taint (OCTR-750).
cloud_provider: external
%{ endif ~}
%{ if external_cloud_provider != "" ~}
# Select a CCM managed by Kubespray. Leave this empty when GitOps owns the CCM.
external_cloud_provider: ${external_cloud_provider}
%{ endif ~}
%{ if sysctl_file_path != "" ~}
sysctl_file_path: "${sysctl_file_path}"
%{ endif ~}
%{ if sysctl_ignore_unknown_keys != null ~}
sysctl_ignore_unknown_keys: ${sysctl_ignore_unknown_keys}
%{ endif ~}
%{ if length(additional_sysctl) > 0 ~}
additional_sysctl:
%{ for sysctl in additional_sysctl ~}
  - name: "${sysctl.name}"
    value: "${sysctl.value}"
%{ endfor ~}
%{ endif ~}
