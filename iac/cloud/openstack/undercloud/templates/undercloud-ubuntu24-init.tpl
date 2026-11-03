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

package_update: true
package_upgrade: true

ntp:
  enabled: true
  servers:
%{for server in ntp_servers~}
    - ${server}
%{endfor~}

# A GPU node has to reboot before it joins the cluster, otherwise the NVIDIA
# driver loads against a kernel command line whose PCI bridge windows were never
# re-balanced. This template has no general reboot switch, so the reboot is tied
# to the GPU flag alone.
%{if enable_pci_realloc~}
power_state:
  mode: reboot
%{endif~}

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

  # GPU nodes need the PCI bridge windows re-balanced at boot so that large
  # NVIDIA BARs get allocated. The script is installed as a grub.d snippet so
  # that it is re-applied by every `update-grub`, including the ones triggered
  # by a kernel or grub package upgrade that resets /etc/default/grub.
%{if enable_pci_realloc~}
  - content: |
      #!/bin/sh
      # Managed by cloud-init. Appends the NVIDIA BAR allocation options to
      # GRUB_CMDLINE_LINUX.
      #
      # Idempotency: the option set is rebuilt from scratch on every run -- any
      # existing pci=/assign-busses/nocrs token is dropped before the canonical
      # set is appended -- so re-running it (cloud-init re-runs runcmd on every
      # instance rebuild, and update-grub re-sources this snippet) can never
      # stack duplicates. Unrelated options and keys are preserved.
      grub_file=/etc/default/grub
      options="pci=realloc,assign-busses,nocrs"

      [ -f "$grub_file" ] || exit 0
      grep -q '^GRUB_CMDLINE_LINUX=' "$grub_file" || exit 0

      # The awk program is written to a file instead of passed inline: this
      # snippet is delivered through a YAML literal block, and an inline
      # single-quoted awk program cannot survive that nesting.
      awk_script=$(mktemp) || exit 1
      cat > "$awk_script" <<'AWK'
      /^GRUB_CMDLINE_LINUX=/ && !done {
        value = $0
        sub(/^[^=]*=[ \t]*/, "", value)

        # A trailing comment outside the quoting is re-emitted untouched rather
        # than being swallowed as a kernel option.
        comment = ""
        if (match(value, /[ \t]+#[^"']*/)) {
          comment = substr(value, RSTART)
          value   = substr(value, 1, RSTART - 1)
        }

        # Strip the surrounding quote, then any comment inside it. Without this
        # a single-quoted or unquoted value had its own key text absorbed as a
        # kernel option.
        first = substr(value, 1, 1)
        if (first == "\"" || first == "\047") value = substr(value, 2)
        sub(/[ \t]*#.*$/, "", value)
        sub(/["']$/, "", value)
        sub(/[ \t]+$/, "", value)

        n = split(value, a, /[ \t]+/)
        out = ""
        for (i = 1; i <= n; i++) {
          if (a[i] == "" || a[i] ~ /^pci=/ || a[i] == "assign-busses" || a[i] == "nocrs") continue
          out = out ((out == "") ? "" : " ") a[i]
        }
        out = (out == "") ? options : out " " options
        printf "GRUB_CMDLINE_LINUX=\"%s\"%s\n", out, comment
        done = 1
        next
      }
      { print }
      AWK

      awk -v options="$options" -f "$awk_script" "$grub_file" > "$grub_file.tmp" && mv "$grub_file.tmp" "$grub_file"
      rc=$?
      rm -f "$awk_script"
      exit $rc
    path: /etc/grub.d/00_pci_realloc
    permissions: '0755'
    owner: root:root
%{endif~}

runcmd:
  - [ /usr/local/sbin/apply-undercloud-netplan ]
%{if enable_pci_realloc~}
  # Apply the kernel command line before the node joins the cluster. The probe
  # is the safety net: a pool flagged by mistake leaves the node untouched.
  - |
    set -eu
    if [ ! -d /sys/bus/pci/devices ]; then
      echo "pci-realloc: no sysfs PCI enumeration; refusing to change the kernel command line" >&2
      exit 1
    fi
    nvidia_devices=$(grep -lx 0x10de /sys/bus/pci/devices/*/vendor 2>/dev/null || true)
    if [ -z "$nvidia_devices" ]; then
      echo "pci-realloc: enabled for this pool but no NVIDIA (0x10de) PCI device found; leaving the kernel command line unchanged"
      exit 0
    fi
    /etc/grub.d/00_pci_realloc
    if command -v update-grub >/dev/null 2>&1; then
      update-grub
    elif command -v update-grub2 >/dev/null 2>&1; then
      update-grub2
    else
      echo "pci-realloc: no update-grub available; cannot regenerate grub.cfg" >&2
      exit 1
    fi
    if command -v update-initramfs >/dev/null 2>&1; then
      update-initramfs -u
    fi
    # kured picks this up for any later reboot; the boot that cloud-init itself
    # performs is handled by power_state above.
    touch /var/run/reboot-required
%{endif~}
