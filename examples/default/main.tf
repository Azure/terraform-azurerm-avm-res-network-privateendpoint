terraform {
  required_version = ">= 1.16, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 5.0.0"
    }
    modtm = {
      source  = "registry.terraform.io/azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.8.2"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"

  legacy_mode = true
}

module "resource_group" {
  source    = "Azure/avm-res-resources-resourcegroup/azurerm"
  version   = "0.4.0"
  providers = { modtm = modtm }

  location         = module.regions.regions[random_integer.region_index.result].name
  name             = module.naming.resource_group.name_unique
  enable_telemetry = var.enable_telemetry
}

module "key_vault" {
  source    = "Azure/avm-res-keyvault-vault/azurerm"
  version   = "0.11.0"
  providers = { modtm = modtm }

  location            = module.resource_group.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = module.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
}

module "virtual_network" {
  source    = "Azure/avm-res-network-virtualnetwork/azurerm"
  version   = "0.22.2"
  providers = { modtm = modtm }

  location         = module.resource_group.location
  parent_id        = module.resource_group.resource_id
  address_space    = ["10.0.0.0/16"]
  enable_telemetry = var.enable_telemetry
  name             = module.naming.virtual_network.name_unique
  subnets = {
    default = {
      address_prefixes = ["10.0.1.0/24"]
      name             = module.naming.subnet.name_unique
    }
  }
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"
  providers = {
    azapi = azapi
  }

  location                       = module.resource_group.location
  name                           = module.naming.private_endpoint.name_unique
  network_interface_name         = module.naming.network_interface.name_unique
  parent_id                      = module.resource_group.resource_id
  private_connection_resource_id = module.key_vault.resource_id
  subnet_resource_id             = module.virtual_network.subnets["default"].resource_id
  # source             = "terraform-azurerm-avm-res-network-privateendpoint/azurerm"
  # ...
  enable_telemetry  = var.enable_telemetry # see variables.tf
  subresource_names = ["vault"]
}
