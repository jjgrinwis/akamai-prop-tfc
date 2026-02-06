# TFC Workspace Reader Module

This module reads workspaces from Terraform Cloud based on tag filters and extracts their output values.

## Purpose

Query multiple TFC workspaces to collect their hostnames (or other outputs) based on tags. Useful for:

- Aggregating hostnames across multiple environments with the same certificate
- Creating combined configurations from related workspaces
- Discovering resources managed by other workspaces

## Usage

```hcl
module "cert_workspaces" {
  source = "../../modules/tfc-workspace-reader"

  organization = "grinwis-com"
  project      = "mendix"
  tag_filter   = "cert:cert-example"
}

# Use the outputs
output "all_hostnames" {
  value = module.cert_workspaces.hostnames
}

output "hostnames_by_workspace" {
  value = module.cert_workspaces.workspace_hostnames
}
```

## Inputs

| Name         | Description              | Type   | Default       | Required |
| ------------ | ------------------------ | ------ | ------------- | -------- |
| organization | TFC organization name    | string | "grinwis-com" | no       |
| project      | TFC project name         | string | "mendix"      | no       |
| tag_filter   | Tag to filter workspaces | string | -             | yes      |

## Outputs

| Name                | Description                                         |
| ------------------- | --------------------------------------------------- |
| hostnames           | Flat list of all hostnames from matching workspaces |
| workspace_hostnames | Map of workspace names to their hostnames           |
| workspace_count     | Number of workspaces matching the tag               |
| workspace_names     | List of workspace names matching the tag            |

## Example Output

```hcl
hostnames = [
  "example.grinwis.com",
  "api.test.nl",
  "www.test.nl"
]

workspace_hostnames = {
  "akamai-prop-example" = ["example.grinwis.com"]
  "akamai-prop-api.test.nl" = ["api.test.nl"]
  "akamai-prop-www.test.nl" = ["www.test.nl"]
}

workspace_count = 3
workspace_names = [
  "akamai-prop-example",
  "akamai-prop-api.test.nl",
  "akamai-prop-www.test.nl"
]
```

## Requirements

- TFC token must be configured (via `terraform login` or `TFC_TOKEN` environment variable)
- The workspaces must have a `hostnames` output defined
- Workspaces must be tagged with the filter tag

## Notes

- Only workspaces with the specified tag are queried
- If a workspace doesn't have a `hostnames` output, it's excluded from results
- The module uses the `tfe` provider which requires authentication to TFC
