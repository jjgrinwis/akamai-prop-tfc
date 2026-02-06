config {
  # Enable module inspection
  module = true

  # Module inspection behavior: local-only, all, or none
  call_module_type = "all"

  # Force provider plugin downloads
  force = false
}

# Enable Terraform plugin (checks Terraform-specific issues)
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Terraform core rules
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true

  # Naming convention for variables
  variable {
    format = "snake_case"
  }

  # Naming convention for outputs
  output {
    format = "snake_case"
  }

  # Naming convention for local values
  locals {
    format = "snake_case"
  }

  # Naming convention for modules
  module {
    format = "snake_case"
  }
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}
