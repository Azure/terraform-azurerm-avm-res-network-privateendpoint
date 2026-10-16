output "name" {
  description = "Name of the private DNS zone group."
  value       = azapi_resource.this.name
}

output "private_dns_zone_configs" {
  description = "Private DNS zone configurations and record sets returned for the private endpoint."
  value       = azapi_resource.this.output.private_dns_zone_configs
}

output "resource_id" {
  description = "ID of the private DNS zone group."
  value       = azapi_resource.this.id
}
