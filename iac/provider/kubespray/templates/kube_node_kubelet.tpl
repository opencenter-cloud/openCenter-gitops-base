---
%{~ if kubelet_cpu_manager_policy != "" }
kubelet_cpu_manager_policy: ${kubelet_cpu_manager_policy}
%{~ endif }
%{~ if kubelet_topology_manager_policy != "" }
kubelet_topology_manager_policy: ${kubelet_topology_manager_policy}
%{~ endif }
%{~ if kubelet_reserved_system_cpus != "" || length(kubelet_config_extra_args) > 0 }
kubelet_config_extra_args:
%{~ if kubelet_reserved_system_cpus != "" }
  reservedSystemCPUs: "${kubelet_reserved_system_cpus}"
%{~ endif }
%{~ for key, value in kubelet_config_extra_args }
%{~ if key != "reservedSystemCPUs" }
  ${key}: "${value}"
%{~ endif }
%{~ endfor }
%{~ endif }
