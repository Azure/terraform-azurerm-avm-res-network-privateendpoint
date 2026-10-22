output "application_security_group_association_ids" {
  description = "The resource IDs of application security groups attached to the private endpoint."
  value = [
    for association in try(azapi_resource.this.output.properties.applicationSecurityGroups, []) :
    association.id
  ]
}

output "name" {
  description = "Name of the resource."
  value       = azapi_resource.this.name
}

output "network_interface_ids" {
  description = "The resource IDs of the network interfaces created for the private endpoint."
  value       = [terraform_data.network_interface_id.output]
}

output "private_ip_addresses" {
  description = "The private IP addresses assigned to the private endpoint."
  value       = data.azapi_resource.network_interface.output.private_ip_addresses
}

output "resource_id" {
  description = "ID of the resource."
  value       = azapi_resource.this.id
}
