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
  # Prevent cloud-init from recreating datasource netplan on subsequent boots.
  - path: /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
    owner: root:root
    permissions: '0644'
    content: |
      network: {config: disabled}

  # Stage the complete desired configuration for validation before installation.
  - path: /var/lib/undercloud-netplan/etc/netplan/50-undercloud.yaml
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

runcmd:
  - |
      set -eu
      LIVE_DIR=/etc/netplan
      NEXT_DIR=/etc/netplan.undercloud
      BACKUP_DIR=/etc/netplan.cloud-init-backup

      restore_netplan() {
        if [ -d "$BACKUP_DIR" ]; then
          rm -rf "$LIVE_DIR"
          mv "$BACKUP_DIR" "$LIVE_DIR"
          netplan generate || true
          netplan apply || true
        fi
      }

      netplan generate --root-dir /var/lib/undercloud-netplan
      rm -rf "$NEXT_DIR" "$BACKUP_DIR"
      install -d -m 0755 "$NEXT_DIR"
      install -m 0600 /var/lib/undercloud-netplan/etc/netplan/50-undercloud.yaml "$NEXT_DIR/50-undercloud.yaml"
%{if metallb_netplan != ""~}
      install -m 0600 /var/lib/undercloud-netplan/etc/netplan/60-metallb-public-pools.yaml "$NEXT_DIR/60-metallb-public-pools.yaml"
%{endif~}

      trap restore_netplan EXIT HUP INT TERM
      mv "$LIVE_DIR" "$BACKUP_DIR"
      mv "$NEXT_DIR" "$LIVE_DIR"
      netplan generate
      netplan apply
      rm -rf "$BACKUP_DIR"
      trap - EXIT HUP INT TERM
      touch /run/undercloud-netplan-configured

power_state:
  mode: reboot
  timeout: 30
  message: "Rebooting to activate persistent undercloud netplan configuration"
  condition: [test, -f, /run/undercloud-netplan-configured]
