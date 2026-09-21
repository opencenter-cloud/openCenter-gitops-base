---
# Managed by Terraform (iac/provider/kubespray) — do not edit by hand.
# Kubelet eviction configuration rendered into a Kubespray group_vars file.
# Values are passed through to the node's KubeletConfiguration via
# kubelet_config_extra_args, which Kubespray writes verbatim into the kubelet
# config. See https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/
#
# merge_default_eviction_settings = ${merge_default_eviction_settings}
#   true  : the eviction_hard thresholds below are merged with kubelet's built-in
#           defaults — signals not listed here keep the kubelet default value.
#   false : Kubespray is instructed not to merge, so only the thresholds listed
#           here apply and kubelet's defaults for unlisted signals are dropped.
kubelet_hard_eviction_thresholds_merge: ${merge_default_eviction_settings}
%{~ if length(eviction_hard) > 0 || length(eviction_soft) > 0 || eviction_max_pod_grace_period != null }
kubelet_config_extra_args:
%{~ if length(eviction_hard) > 0 }
  evictionHard:
%{~ for signal, threshold in eviction_hard }
    ${signal}: "${threshold}"
%{~ endfor }
%{~ endif }
%{~ if length(eviction_soft) > 0 }
  evictionSoft:
%{~ for signal, threshold in eviction_soft }
    ${signal}: "${threshold}"
%{~ endfor }
  evictionSoftGracePeriod:
%{~ for signal, period in eviction_soft_grace_period }
    ${signal}: "${period}"
%{~ endfor }
%{~ endif }
%{~ if eviction_max_pod_grace_period != null }
  evictionMaxPodGracePeriod: ${eviction_max_pod_grace_period}
%{~ endif }
%{~ endif }
