---
containerd_cri_extra_settings:
%{ for key, value in containerd_cri_extra_settings ~}
%{ if try(tolist(value), null) != null ~}
  ${key}:
%{ for item in value ~}
    - "${item}"
%{ endfor ~}
%{ else ~}
%{ if try(tobool(value), null) != null ~}
  ${key}: ${lower(tostring(value))}
%{ else ~}
%{ if try(tomap(value), null) != null ~}
  ${key}:
%{ for k, v in value ~}
    ${k}: ${v}
%{ endfor ~}
%{ else ~}
  ${key}: ${value}
%{ endif ~}
%{ endif ~}
%{ endif ~}
%{ endfor ~}
