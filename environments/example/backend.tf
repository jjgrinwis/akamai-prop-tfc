terraform {
  cloud {
    organization = "grinwis-com"
    workspaces {
      name = "akamai-prop-example"
      # Workspace name is automatically set to: akamai-prop-<directory-name>
      # This will be auto-updated by 'make init' to match the directory
      #name    = "akamai-prop-example"
      project = "mendix"
    }
  }
}
