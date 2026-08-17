installation:
  enabled: true
  kubernetesProvider: ""
  calicoNetwork:
    windowsDataplane: "${windows_dataplane}"
    nodeAddressAutodetectionV4:
%{ if calico_interface_autodetect == "interface" ~}
      interface: "${cni_iface}"
%{ endif ~}
%{ if calico_interface_autodetect == "cidr" ~}
      cidr: "${calico_interface_autodetect_cidr}"
%{ endif ~}
%{ if calico_interface_autodetect == "first-found" ~}
      firstFound: true
%{ endif ~}
    ipPools:
      - cidr: "${subnet_pods}"
        encapsulation: "${calico_encapsulation_type}"
        natOutgoing: ${calico_nat_outgoing}
  serviceCIDRs:
    - "${subnet_services}"

# Preserve the module's historical explicit Kubernetes API endpoint by default.
# Set kubernetes_service_endpoint_enabled to false to use the in-cluster
# Kubernetes service endpoint instead.
%{ if kubernetes_service_endpoint_enabled ~}
kubernetesServiceEndpoint:
  host: "${k8s_internal_ip}"
  port: "${k8s_api_port}"
%{ endif ~}
