---
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