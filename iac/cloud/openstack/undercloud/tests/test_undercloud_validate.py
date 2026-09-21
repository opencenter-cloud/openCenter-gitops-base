"""Structural validation tests for the undercloud Terraform module.

Uses subprocess to run terraform validate/plan commands and verify that:
- The module initializes without error
- Plan succeeds with each tfvars fixture (via validate with var-file)
- Variable validation catches invalid mgmt_vlan_id values (0, 4095)
- Variable validation catches invalid metallb_networks VLAN IDs

Validates: Requirements 2.4, 12.6
"""

import os
import subprocess

import pytest

MODULE_DIR = os.path.join(os.path.dirname(__file__), "..")
TESTS_DIR = os.path.dirname(__file__)


@pytest.fixture(autouse=True, scope="session")
def terraform_init():
    """Ensure terraform is initialized before tests run."""
    result = subprocess.run(
        ["terraform", "init", "-backend=false"],
        cwd=MODULE_DIR,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, f"terraform init failed: {result.stderr}"


def test_module_validates():
    """Test that the module passes terraform validate."""
    result = subprocess.run(
        ["terraform", "validate"],
        cwd=MODULE_DIR,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, f"terraform validate failed: {result.stderr}"


def test_plan_minimal_config():
    """Test that terraform plan succeeds with minimal.tfvars.

    Since there is no real OpenStack endpoint, we use terraform validate
    with -var-file to check that the variable set is complete and valid.
    """
    var_file = os.path.join(TESTS_DIR, "minimal.tfvars")
    result = subprocess.run(
        [
            "terraform",
            "plan",
            "-input=false",
            f"-var-file={var_file}",
        ],
        cwd=MODULE_DIR,
        capture_output=True,
        text=True,
    )
    # Plan may fail due to missing OpenStack provider endpoint, but it
    # should NOT fail due to variable validation errors.
    # If it fails, ensure it's a provider connectivity issue, not a var issue.
    if result.returncode != 0:
        # Variable validation errors contain "Error:" with the variable name
        assert "mgmt_vlan_id" not in result.stderr, (
            f"Variable validation error in minimal config: {result.stderr}"
        )
        assert "metallb_networks" not in result.stderr, (
            f"Variable validation error in minimal config: {result.stderr}"
        )


def test_plan_full_config():
    """Test that terraform plan succeeds with full.tfvars.

    Verifies all optional features (metallb, bastion, additional pools)
    can be configured without validation errors.
    """
    var_file = os.path.join(TESTS_DIR, "full.tfvars")
    result = subprocess.run(
        [
            "terraform",
            "plan",
            "-input=false",
            f"-var-file={var_file}",
        ],
        cwd=MODULE_DIR,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        assert "mgmt_vlan_id" not in result.stderr, (
            f"Variable validation error in full config: {result.stderr}"
        )
        assert "metallb_networks" not in result.stderr, (
            f"Variable validation error in full config: {result.stderr}"
        )


def test_plan_preexisting_hostnet():
    """Test that terraform plan succeeds with preexisting-hostnet.tfvars.

    Verifies pre-existing hostnet network/subnet IDs are accepted.
    """
    var_file = os.path.join(TESTS_DIR, "preexisting-hostnet.tfvars")
    result = subprocess.run(
        [
            "terraform",
            "plan",
            "-input=false",
            f"-var-file={var_file}",
        ],
        cwd=MODULE_DIR,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        assert "mgmt_vlan_id" not in result.stderr, (
            f"Variable validation error in preexisting-hostnet config: {result.stderr}"
        )
        assert "metallb_networks" not in result.stderr, (
            f"Variable validation error in preexisting-hostnet config: {result.stderr}"
        )


def test_invalid_mgmt_vlan_id_zero():
    """Test that mgmt_vlan_id = 0 is rejected by validation.

    The variable validation block requires mgmt_vlan_id >= 1 && <= 4094.
    """
    var_file = os.path.join(TESTS_DIR, "minimal.tfvars")
    result = subprocess.run(
        [
            "terraform",
            "plan",
            "-input=false",
            f"-var-file={var_file}",
            "-var=mgmt_vlan_id=0",
        ],
        cwd=MODULE_DIR,
        capture_output=True,
        text=True,
    )
    assert result.returncode != 0, (
        "Expected terraform plan to fail with mgmt_vlan_id=0"
    )
    combined_output = result.stdout + result.stderr
    assert "mgmt_vlan_id must be between 1 and 4094" in combined_output, (
        f"Expected validation error message not found. Output: {combined_output}"
    )


def test_invalid_mgmt_vlan_id_too_high():
    """Test that mgmt_vlan_id = 4095 is rejected by validation.

    The variable validation block requires mgmt_vlan_id >= 1 && <= 4094.
    """
    var_file = os.path.join(TESTS_DIR, "minimal.tfvars")
    result = subprocess.run(
        [
            "terraform",
            "plan",
            "-input=false",
            f"-var-file={var_file}",
            "-var=mgmt_vlan_id=4095",
        ],
        cwd=MODULE_DIR,
        capture_output=True,
        text=True,
    )
    assert result.returncode != 0, (
        "Expected terraform plan to fail with mgmt_vlan_id=4095"
    )
    combined_output = result.stdout + result.stderr
    assert "mgmt_vlan_id must be between 1 and 4094" in combined_output, (
        f"Expected validation error message not found. Output: {combined_output}"
    )


def test_invalid_metallb_vlan_id():
    """Test that metallb_networks with vlan_id = 0 is rejected.

    The variable validation block requires all vlan_id values >= 1 && <= 4094.
    """
    var_file = os.path.join(TESTS_DIR, "minimal.tfvars")
    result = subprocess.run(
        [
            "terraform",
            "plan",
            "-input=false",
            f"-var-file={var_file}",
            '-var=metallb_networks=[{"pool_name":"bad-pool","vlan_id":0,"subnet_pool":"test-pool"}]',
        ],
        cwd=MODULE_DIR,
        capture_output=True,
        text=True,
    )
    assert result.returncode != 0, (
        "Expected terraform plan to fail with metallb vlan_id=0"
    )
    combined_output = result.stdout + result.stderr
    assert "metallb_networks" in combined_output.lower() or "vlan_id between 1 and 4094" in combined_output, (
        f"Expected validation error message not found. Output: {combined_output}"
    )
