---
%{ if external_cloud_provider != "" ~}
# Run kubelet with --cloud-provider=external so an external cloud controller
# manager (CCM) initializes each node (sets spec.providerID and clears the
# node.cloudprovider.kubernetes.io/uninitialized taint). Required for OpenStack
# CCM LoadBalancer/Octavia provisioning. See OCTR-750.
#
# Two kubespray variables are required and are NOT interchangeable:
#   - cloud_provider: external  -> makes kubelet pass --cloud-provider=external
#     (KUBELET_CLOUDPROVIDER) and taint nodes with
#     node.cloudprovider.kubernetes.io/uninitialized.
#   - external_cloud_provider: <name> -> selects which external CCM kubespray
#     wires up (openstack, vsphere, ...).
# Setting only external_cloud_provider leaves the kubelet flag empty, so the
# CCM never initializes providerID. Set both.
cloud_provider: external
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