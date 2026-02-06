# Data source to get all workspaces in the organization
data "tfe_workspace_ids" "all" {
  organization = var.organization
  tag_names    = [var.tag_filter]
}

# Read outputs from each workspace that matches the tag
data "tfe_outputs" "workspaces" {
  for_each = data.tfe_workspace_ids.all.ids

  organization = var.organization
  workspace    = each.key
}

# Combine all hostnames from matching workspaces
locals {
  # Extract hostnames from each workspace's outputs
  all_hostnames = flatten([
    for workspace_name, outputs in data.tfe_outputs.workspaces :
    try(nonsensitive(outputs.values.hostnames), [])
  ])

  # Create a map of workspace names to their hostnames
  workspace_hostnames = {
    for workspace_name, outputs in data.tfe_outputs.workspaces :
    workspace_name => try(nonsensitive(outputs.values.hostnames), [])
  }
}
