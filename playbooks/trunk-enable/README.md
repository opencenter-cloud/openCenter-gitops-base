# Trunk Enable (Pre-Destroy)

Re-enables disabled trunk ports so `terraform destroy` can proceed.

## Why?

When undercloud servers are deleted or the platform hits certain conditions, trunk ports get administratively disabled. Terraform destroy will fail trying to delete disabled trunks. This playbook flips them back to enabled.

## Configuration

Edit `vars.yml` with your trunk IDs:

```yaml
os_cloud: uc-oc-stage
trunk_ids:
  - <trunk-id-1>
  - <trunk-id-2>
  - ...
```

Find trunk IDs with:
```bash
 openstack --os-cloud uc-oc-stage network trunk list -f value -c ID | sed 's/^/  - /'
```

## Usage

```bash
# Run before terraform destroy
ansible-playbook playbooks/trunk-enable/trunk-enable.yml

# With a different cloud
ansible-playbook playbooks/trunk-enable/trunk-enable.yml -e os_cloud=my-other-cloud

# With custom vars file
ansible-playbook playbooks/trunk-enable/trunk-enable.yml -e @/path/to/vars.yml
```

Then proceed with:
```bash
terraform destroy
```
