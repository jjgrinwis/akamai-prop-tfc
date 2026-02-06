output "all_hostnames" {
  description = "All hostnames from workspaces tagged with cert:cert-example"
  value       = module.cert_example_workspaces.hostnames
}

output "hostnames_by_workspace" {
  description = "Map of workspace names to their hostnames"
  value       = module.cert_example_workspaces.workspace_hostnames
}

output "workspace_count" {
  description = "Number of workspaces with this certificate tag"
  value       = module.cert_example_workspaces.workspace_count
}

output "workspace_names" {
  description = "Names of all workspaces using this certificate"
  value       = module.cert_example_workspaces.workspace_names
}
