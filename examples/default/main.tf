terraform {
  required_version = ">= 1.16, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azapi" {}

data "azapi_client_config" "current" {}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.13.2"

  location         = "eastus2"
  enable_telemetry = var.enable_telemetry
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"

  unique_length = 8
}

resource "azapi_resource" "resource_group" {
  location               = module.regions.regions[random_integer.region_index.result].name
  name                   = module.naming.names.resource_group.name_unique
  parent_id              = data.azapi_client_config.current.subscription_resource_id
  type                   = "Microsoft.Resources/resourceGroups@2024-07-01"
  body                   = {}
  response_export_values = []
}

resource "azapi_resource" "key_vault" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.names.key_vault_vault.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.KeyVault/vaults@2023-07-01"
  body = {
    properties = {
      accessPolicies          = []
      enablePurgeProtection   = true
      enableRbacAuthorization = true
      networkAcls = {
        bypass        = "None"
        defaultAction = "Deny"
      }
      publicNetworkAccess = "Enabled"
      sku = {
        family = "A"
        name   = "premium"
      }
      tenantId = data.azapi_client_config.current.tenant_id
    }
  }
  response_export_values = []
}

resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.names.virtual_network.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "subnet" {
  name      = module.naming.names.virtual_network_subnet.name_unique
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix                  = "10.0.1.0/24"
      privateEndpointNetworkPolicies = "Enabled"
    }
  }
  response_export_values = []
}

module "test" {
  source = "../../"

  location                       = azapi_resource.resource_group.location
  name                           = module.naming.names.private_endpoint.name_unique
  network_interface_name         = module.naming.names.network_interface.name_unique
  parent_id                      = azapi_resource.resource_group.id
  private_connection_resource_id = azapi_resource.key_vault.id
  subnet_resource_id             = azapi_resource.subnet.id
  enable_telemetry               = var.enable_telemetry
  subresource_names              = ["vault"]
}
