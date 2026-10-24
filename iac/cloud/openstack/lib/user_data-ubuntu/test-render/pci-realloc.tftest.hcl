# The NVIDIA BAR allocation kernel options must reach a node's GRUB command line
# only when the pool opts in, and only through a mechanism that survives a grub
# package reinstall. The assertions run against the rendered cloud-config.

run "disabled_by_default" {
  command = plan

  assert {
    condition     = output.cloud_config != ""
    error_message = "The cloud-config must always render."
  }

  assert {
    condition     = length([for f in yamldecode(output.cloud_config).write_files : f if f.path == "/etc/grub.d/00_pci_realloc"]) == 0
    error_message = "The grub drop-in must not be installed when enable_pci_realloc is false."
  }

  assert {
    condition     = length([for c in try(yamldecode(output.cloud_config).runcmd, []) : c if can(regex("00_pci_realloc", tostring(c)))]) == 0
    error_message = "No grub rewrite may run when enable_pci_realloc is false."
  }

  assert {
    condition     = !can(regex("pci=realloc,assign-busses,nocrs", output.cloud_config))
    error_message = "The kernel options must be absent from the render when the flag is false."
  }
}

run "enabled_installs_grub_dropin" {
  command = plan

  variables {
    enable_pci_realloc = true
  }

  assert {
    condition     = length([for f in yamldecode(output.cloud_config).write_files : f if f.path == "/etc/grub.d/00_pci_realloc"]) == 1
    error_message = "Exactly one grub.d drop-in must be installed when enable_pci_realloc is true."
  }

  assert {
    condition     = one([for f in yamldecode(output.cloud_config).write_files : f.permissions if f.path == "/etc/grub.d/00_pci_realloc"]) == "0755"
    error_message = "The grub.d snippet must be executable or update-grub will skip it."
  }

  # update-grub only sources /etc/grub.d/00_header, so the fix has to live in a
  # numbered snippet that update-grub re-applies after a package reinstall.
  assert {
    condition     = can(regex("GRUB_CMDLINE_LINUX", one([for f in yamldecode(output.cloud_config).write_files : f.content if f.path == "/etc/grub.d/00_pci_realloc"])))
    error_message = "The drop-in must rewrite GRUB_CMDLINE_LINUX."
  }

  assert {
    condition     = length([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))]) == 1
    error_message = "Exactly one runcmd entry must apply the grub rewrite when the flag is true."
  }

  # Guards against the insertion clobbering a neighbouring runcmd entry.
  assert {
    condition     = length([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("reload ssh.service", tostring(c)))]) == 1
    error_message = "The existing runcmd entries must survive the insertion unchanged."
  }
}

run "enabled_probes_before_touching_grub" {
  command = plan

  variables {
    enable_pci_realloc = true
  }

  # A pool flagged by mistake must leave a CPU-only node completely untouched.
  assert {
    condition     = can(regex("0x10de", one([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))])))
    error_message = "The runcmd entry must probe for an NVIDIA PCI device before changing the kernel command line."
  }

  assert {
    condition     = can(regex("set -eu", one([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))])))
    error_message = "The runcmd entry must fail fast rather than half-configure the node."
  }

  # The reboot is delegated to power_state, which already gates on var.reboot.
  assert {
    condition     = !can(regex("^reboot$", trimspace(one([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))]))))
    error_message = "The runcmd entry must not reboot the node itself; power_state owns the reboot."
  }

  assert {
    condition     = can(regex("/var/run/reboot-required", one([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))])))
    error_message = "The node must raise the reboot-required flag so kured can stage later reboots."
  }

  assert {
    condition     = try(yamldecode(output.cloud_config).power_state.mode, null) == "reboot"
    error_message = "With reboot = true the node must reboot during cloud-init so the option is live before it joins the cluster."
  }
}

run "enabled_without_reboot_defers_to_power_state" {
  command = plan

  variables {
    enable_pci_realloc = true
    reboot             = false
  }

  assert {
    condition     = can(regex("00_pci_realloc", output.cloud_config))
    error_message = "The grub rewrite must still be installed when the operator suppresses the cloud-init reboot."
  }

  assert {
    condition     = try(yamldecode(output.cloud_config).power_state, null) == null
    error_message = "power_state must stay absent when reboot = false; the GPU flag must not force a reboot."
  }
}

# The three templates are separate files, so each one has to carry the block and
# each one is asserted on by name; a run that does not pin ub_version would
# silently keep testing ubuntu-init.tpl for every template.
run "enabled_for_default_template" {
  command = plan

  variables {
    enable_pci_realloc = true
    ub_version         = ""
  }

  assert {
    condition     = length([for f in yamldecode(output.cloud_config).write_files : f if f.path == "/etc/grub.d/00_pci_realloc"]) == 1
    error_message = "ubuntu-init.tpl must install the grub drop-in."
  }

  assert {
    condition     = length([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))]) == 1
    error_message = "ubuntu-init.tpl must run the grub rewrite."
  }

  assert {
    condition     = can(regex("0x10de", one([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))])))
    error_message = "ubuntu-init.tpl must probe for an NVIDIA device before rewriting grub."
  }
}

run "enabled_for_ubuntu22_template" {
  command = plan

  variables {
    enable_pci_realloc = true
    ub_version         = "22"
  }

  assert {
    condition     = length([for f in yamldecode(output.cloud_config).write_files : f if f.path == "/etc/grub.d/00_pci_realloc"]) == 1
    error_message = "ubuntu-init22.tpl must install the grub drop-in."
  }

  assert {
    condition     = length([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))]) == 1
    error_message = "ubuntu-init22.tpl must run the grub rewrite."
  }

  assert {
    condition     = can(regex("0x10de", one([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))])))
    error_message = "ubuntu-init22.tpl must probe for an NVIDIA device before rewriting grub."
  }
}

run "enabled_for_ubuntu24_template" {
  command = plan

  variables {
    enable_pci_realloc = true
    ub_version         = "24"
  }

  assert {
    condition     = length([for f in yamldecode(output.cloud_config).write_files : f if f.path == "/etc/grub.d/00_pci_realloc"]) == 1
    error_message = "ubuntu-init24.tpl must install the grub drop-in."
  }

  assert {
    condition     = length([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))]) == 1
    error_message = "ubuntu-init24.tpl must run the grub rewrite."
  }

  assert {
    condition     = can(regex("0x10de", one([for c in yamldecode(output.cloud_config).runcmd : c if can(regex("00_pci_realloc", tostring(c)))])))
    error_message = "ubuntu-init24.tpl must probe for an NVIDIA device before rewriting grub."
  }
}
