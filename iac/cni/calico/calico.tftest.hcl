run "default_first_found" {
  command = plan

  assert {
    condition     = output.calico_autodetection.mode == "first-found"
    error_message = "The default autodetection mode must be first-found."
  }

  assert {
    condition     = yamldecode(output.calico_values).installation.calicoNetwork.nodeAddressAutodetectionV4 == { firstFound = true }
    error_message = "Default values must emit only firstFound."
  }
}

run "normalized_first_found" {
  command = plan

  variables {
    calico_interface_autodetect = "  FIRST-FOUND  "
  }

  assert {
    condition     = yamldecode(output.calico_values).installation.calicoNetwork.nodeAddressAutodetectionV4 == { firstFound = true }
    error_message = "First-found mode must emit only firstFound."
  }
}

run "interface" {
  command = plan

  variables {
    calico_interface_autodetect      = " Interface "
    cni_iface                        = "  Ethernet 2  "
    calico_interface_autodetect_cidr = "10.99.0.0/16"
  }

  assert {
    condition     = output.calico_autodetection.interface == "Ethernet 2"
    error_message = "The interface must be trimmed without changing case."
  }

  assert {
    condition     = yamldecode(output.calico_values).installation.calicoNetwork.nodeAddressAutodetectionV4 == { interface = "Ethernet 2" }
    error_message = "Interface mode must emit only the trimmed interface."
  }
}

run "cidr" {
  command = plan

  variables {
    calico_interface_autodetect      = " CIDR "
    calico_interface_autodetect_cidr = " 10.42.0.0/16 "
    cni_iface                        = "eth9"
  }

  assert {
    condition     = yamldecode(output.calico_values).installation.calicoNetwork.nodeAddressAutodetectionV4 == { cidrs = ["10.42.0.0/16"] }
    error_message = "CIDR mode must emit only the trimmed CIDR."
  }
}

run "invalid_mode" {
  command = plan

  variables {
    calico_interface_autodetect = "can-reach"
  }

  expect_failures = [var.calico_interface_autodetect]
}

run "blank_interface" {
  command = plan

  variables {
    calico_interface_autodetect = "interface"
    cni_iface                   = "   "
  }

  expect_failures = [output.calico_values]
}

run "blank_cidr" {
  command = plan

  variables {
    calico_interface_autodetect      = "cidr"
    calico_interface_autodetect_cidr = "   "
  }

  expect_failures = [output.calico_values]
}

run "invalid_cidr" {
  command = plan

  variables {
    calico_interface_autodetect      = "cidr"
    calico_interface_autodetect_cidr = "not-a-cidr"
  }

  expect_failures = [var.calico_interface_autodetect_cidr]
}

run "ipv6_cidr_rejected" {
  command = plan

  variables {
    calico_interface_autodetect      = "cidr"
    calico_interface_autodetect_cidr = "fd00::/64"
  }

  expect_failures = [var.calico_interface_autodetect_cidr]
}
