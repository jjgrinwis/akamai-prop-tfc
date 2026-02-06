variable "environment" {
  description = "Environment name (e.g., dev, staging, prod, api.test.nl)"
  type        = string
}

variable "hostnames" {
  description = "The hostnames of the property"
  type        = list(string)
}

# Add your Akamai-specific variables here
# variable "contract_id" {
#   description = "Akamai contract ID"
#   type        = string
# }

# variable "group_id" {
#   description = "Akamai group ID"
#   type        = string
# }

# variable "product_id" {
#   description = "Akamai product ID"
#   type        = string
#   default     = "prd_SPM"
# }
