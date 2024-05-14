output "name" {
  description = "Name of the resource."
  value       = azurerm_private_endpoint.this.name
}

output "resource" {
  description = "Output of the resource."
  value       = azurerm_private_endpoint.this
}

output "resource_id" {
  description = "ID of the resource."
  value       = azurerm_private_endpoint.this.id
}
