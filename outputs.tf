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
  value = [
    for network_interface in try(azapi_resource.this.output.properties.networkInterfaces, []) :
    network_interface.id
  ]
}

output "private_ip_addresses" {
  description = "The private IP addresses assigned to the private endpoint."
  value = distinct(concat(
    flatten([
      for dns_config in try(azapi_resource.this.output.properties.customDnsConfigs, []) :
      try(dns_config.ipAddresses, [])
    ]),
    compact([
      for ip_configuration in try(azapi_resource.this.output.properties.ipConfigurations, []) :
      try(ip_configuration.properties.privateIPAddress, "")
    ])
  ))
}

output "resource_id" {
  description = "ID of the resource."
  value       = azapi_resource.this.id
}
