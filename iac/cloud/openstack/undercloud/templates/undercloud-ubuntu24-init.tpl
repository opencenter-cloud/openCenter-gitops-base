#cloud-config
%{if ca_certificates != ""~}
ca_certs:
  trusted:
  - |
   ${indent(3, ca_certificates)}
%{endif~}

ssh_authorized_keys:
%{for key in ssh_authorized_keys~}
  - ${key}
%{endfor~}

ntp:
  enabled: true
  servers:
%{for server in ntp_servers~}
    - ${server}
%{endfor~}

write_files:
  # Keep the Terraform-rendered configuration separate until it validates.
  # Datasource networking remains active during the initial boot and SSH setup.
  - path: /var/lib/undercloud-netplan/etc/netplan/50-cloud-init.yaml
    owner: root:root
    permissions: '0600'
    content: |
      ${indent(6, undercloud_netplan)}
%{if metallb_netplan != ""~}
  - path: /var/lib/undercloud-netplan/etc/netplan/60-metallb-public-pools.yaml
    owner: root:root
    permissions: '0600'
    content: |
      ${indent(6, metallb_netplan)}
%{endif~}
  - path: /usr/local/sbin/apply-undercloud-netplan
    owner: root:root
    permissions: '0755'
    content: |
      #!/bin/sh
      set -eu

      root=/var/lib/undercloud-netplan
      staged="$root/etc/netplan"
      backup="$root/original-netplan"

      # Validate the complete candidate before changing active networking.
      netplan generate --root-dir "$root"

      # Preserve the datasource configuration for recovery and troubleshooting.
      if [ ! -d "$backup" ]; then
        cp -a /etc/netplan "$backup"
      fi

      install -m 0600 "$staged/50-cloud-init.yaml" /etc/netplan/50-cloud-init.yaml
      if [ -f "$staged/60-metallb-public-pools.yaml" ]; then
        install -m 0600 "$staged/60-metallb-public-pools.yaml" /etc/netplan/60-metallb-public-pools.yaml
      fi

      netplan generate
      netplan apply

      # Keep the promoted configuration authoritative on later boots.
      printf '%s\n' 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

      # Kubespray will not continue unless this final marker exists.
      touch "$root/ready"

runcmd:
  - [ /usr/local/sbin/apply-undercloud-netplan ]
