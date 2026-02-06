terraform {
  required_version = ">= 1.5"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.51"
    }
  }
}

# TFE provider for reading workspace data
provider "tfe" {
  # Uses token from terraform login or TFC_TOKEN environment variable
}
