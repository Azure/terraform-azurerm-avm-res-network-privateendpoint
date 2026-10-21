data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location  = "eastus2"
  name      = "rg-avm-pe-int-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2024-07-01"
  body      = {}
  response_export_values = {
    location = "location"
    name     = "name"
  }
}

resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.resource_group.location
  name      = "vnet-avm-pe-int-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
    }
  }
  response_export_values = {
    name = "name"
  }
}

resource "azapi_resource" "subnet" {
  name      = "snet-private-endpoint"
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix                  = "10.0.1.0/24"
      privateEndpointNetworkPolicies = "Disabled"
    }
  }
  response_export_values = {
    name = "name"
  }
}

resource "azapi_resource" "private_dns_zone" {
  location  = "global"
  name      = "privatelink.blob.core.windows.net"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/privateDnsZones@2024-06-01"
  body      = {}
  response_export_values = {
    name = "name"
  }
  retry = {
    error_message_regex = ["CannotDeleteResource"]
  }
}

resource "azapi_resource" "private_dns_zone_virtual_network_link" {
  location  = "global"
  name      = "vnet-link-${random_string.suffix.result}"
  parent_id = azapi_resource.private_dns_zone.id
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01"
  body = {
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = azapi_resource.virtual_network.id
      }
    }
  }
  response_export_values = {
    name = "name"
  }
}

resource "azapi_resource" "storage_account" {
  location  = azapi_resource.resource_group.location
  name      = "stpeint${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    properties = {
      allowBlobPublicAccess    = false
      minimumTlsVersion        = "TLS1_2"
      supportsHttpsTrafficOnly = true
    }
    sku = {
      name = "Standard_ZRS"
    }
  }
  response_export_values = {
    name = "name"
  }
}

resource "azapi_resource" "user_assigned_identity" {
  location  = azapi_resource.resource_group.location
  name      = "id-avm-pe-int-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  body      = {}
  response_export_values = {
    name        = "name"
    principalId = "properties.principalId"
  }
}

resource "azapi_resource" "application_security_group" {
  location  = azapi_resource.resource_group.location
  name      = "asg-pe-int-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/applicationSecurityGroups@2024-05-01"
  body      = {}
  response_export_values = {
    name = "name"
  }
}

module "test" {
  source = "../../"
  providers = {
    azapi = azapi
  }

  location                                   = azapi_resource.resource_group.location
  name                                       = "pe-avm-int-${random_string.suffix.result}"
  network_interface_name                     = "nic-pe-avm-int-${random_string.suffix.result}"
  parent_id                                  = azapi_resource.resource_group.id
  private_connection_resource_id             = azapi_resource.storage_account.id
  subnet_resource_id                         = azapi_resource.subnet.id
  application_security_group_association_ids = [azapi_resource.application_security_group.id]
  enable_telemetry                           = var.enable_telemetry
  lock = {
    kind = "CanNotDelete"
  }
  private_dns_zone_group_name   = "default"
  private_dns_zone_resource_ids = [azapi_resource.private_dns_zone.id]
  role_assignments = {
    blob_data_reader = {
      role_definition_id_or_name = "Storage Blob Data Reader"
      principal_id               = azapi_resource.user_assigned_identity.output.principalId
      principal_type             = "ServicePrincipal"
      description                = "E2E coverage for the role assignments interface."
    }
  }
  subresource_names = ["blob"]

  depends_on = [azapi_resource.private_dns_zone_virtual_network_link]
}

output "private_endpoint_resource_id" {
  description = "The resource ID of the private endpoint."
  value       = module.test.resource_id
}

output "user_assigned_identity_resource_id" {
  description = "The resource ID of the user-assigned managed identity used for role assignment coverage."
  value       = azapi_resource.user_assigned_identity.id
}

output "application_security_group_association_ids" {
  description = "Application security groups reported as attached to the private endpoint."

  precondition {
    condition = contains(
      [for id in module.test.application_security_group_association_ids : lower(id)],
      lower(azapi_resource.application_security_group.id)
    )
    error_message = "The complete example private endpoint must retain its configured application security group association."
  }
  value = module.test.application_security_group_association_ids
}

output "private_ip_addresses" {
  description = "Private IP addresses reported by the private endpoint network interface."

  precondition {
    condition     = length(module.test.private_ip_addresses) > 0
    error_message = "The complete example private endpoint must report at least one private IP address from its network interface."
  }
  value = module.test.private_ip_addresses
}
