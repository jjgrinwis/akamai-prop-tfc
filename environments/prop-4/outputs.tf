output "environment" {
  description = "The environment name"
  value       = module.akamai_property.environment
}

output "hostnames" {
  description = "The configured hostnames"
  value       = module.akamai_property.hostnames
}
