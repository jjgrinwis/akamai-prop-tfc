# Example: Reading Workspaces by Certificate Tag

This example demonstrates how to use the `tfc-workspace-reader` module to find all workspaces tagged with `cert:cert-example` and extract their hostnames.

## Usage

```bash
cd examples/read-cert-workspaces
terraform init
terraform plan
terraform apply
```

## What This Does

1. Queries TFC for all workspaces in the "mendix" project
2. Filters workspaces by tag `cert:cert-example`
3. Reads the `hostnames` output from each matching workspace
4. Aggregates all hostnames into a single list

## Example Output

```
all_hostnames = [
  "example.grinwis.com",
]

hostnames_by_workspace = {
  "akamai-prop-example" = ["example.grinwis.com"]
  "akamai-prop-prop-1" = ["example.grinwis.com"]
  "akamai-prop-prop-2" = ["example.grinwis.com"]
}

workspace_count = 3

workspace_names = [
  "akamai-prop-example",
  "akamai-prop-prop-1",
  "akamai-prop-prop-2"
]
```

## Use Cases

- **Certificate Management**: Get all hostnames that share a certificate
- **DNS Configuration**: Aggregate hostnames for bulk DNS operations
- **Compliance Reporting**: Track which workspaces are using specific certificates
- **Resource Discovery**: Find related environments by tag

## Requirements

- Terraform Cloud token (via `terraform login`)
- Access to the "grinwis-com" organization
- Workspaces must have applied at least once to have outputs
