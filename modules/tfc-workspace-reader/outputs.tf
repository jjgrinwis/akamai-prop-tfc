output "hostnames" {
  description = "All hostnames from workspaces matching the tag filter"
  value       = local.all_hostnames
}

output "workspace_hostnames" {
  description = "Map of workspace names to their hostnames"
  value       = local.workspace_hostnames
}

output "workspace_count" {
  description = "Number of workspaces matching the tag filter"
  value       = length(data.tfe_workspace_ids.all.ids)
}

output "workspace_names" {
  description = "List of workspace names matching the tag filter"
  value       = keys(data.tfe_workspace_ids.all.ids)
}
