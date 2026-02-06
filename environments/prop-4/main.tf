# Auto-detect environment name from directory
locals {
  environment = basename(abspath(path.cwd))
}

module "akamai_property" {
  source = "../../modules/akamai-property"

  environment = local.environment
  hostnames   = var.hostnames
}
