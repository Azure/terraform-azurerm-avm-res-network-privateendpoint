output "name" {
  description = "Name of the resource."
  value       = azapi_resource.this.name
}

output "resource" {
  description = "Output of the resource."
  value       = azapi_resource.this
}

output "resource_id" {
  description = "ID of the resource."
  value       = azapi_resource.this.id
}
