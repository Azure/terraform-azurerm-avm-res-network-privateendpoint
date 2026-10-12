output "name" {
  description = "Name of the private DNS zone group."
  value       = azapi_resource.this.name
}

output "resource" {
  description = "Output of the private DNS zone group resource."
  value       = azapi_resource.this
}

output "resource_id" {
  description = "ID of the private DNS zone group."
  value       = azapi_resource.this.id
}
