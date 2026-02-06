# Example: Read all workspaces with cert:cert-example tag

module "cert_example_workspaces" {
  source = "../../modules/tfc-workspace-reader"

  organization = "grinwis-com"
  project      = "mendix"
  tag_filter   = "cert:cert-example"
}

# You can add additional logic here, such as:
# - Creating a combined certificate with all hostnames
# - Generating a configuration file
# - Passing hostnames to another resource
