# Main Akamai property configuration
# Add your Akamai resources here

# Example:
# resource "akamai_property" "main" {
#   name        = "property-${var.environment}"
#   contract_id = var.contract_id
#   group_id    = var.group_id
#   product_id  = var.product_id
#   hostnames   = [var.hostnames]
# }

# For now, just a placeholder
resource "null_resource" "placeholder" {
  triggers = {
    environment = var.environment
    hostnames   = join(",", var.hostnames)
  }
}
