mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = { results = [] }
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      output = { private_ip_addresses = ["10.0.0.4"] }
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateEndpoints/example"
      output = {
        properties = {
          networkInterfaces = [{
            id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/networkInterfaces/example"
          }]
        }
      }
    }
  }
}

mock_provider "random" {}

mock_provider "time" {}

variables {
  location                       = "eastus"
  name                           = "example"
  network_interface_name         = "example"
  parent_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
  private_connection_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Storage/storageAccounts/example"
  subnet_resource_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example/subnets/default"
  subresource_names              = ["blob"]
  lock = {
    kind = "CanNotDelete"
  }
  role_assignments = {
    reader = {
      name                       = "00000000-0000-0000-0000-000000000001"
      role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
      principal_id               = "00000000-0000-0000-0000-000000000002"
      principal_type             = "ServicePrincipal"
    }
  }
}

run "interfaces_with_telemetry" {
  command = apply

  assert {
    condition = (
      azapi_resource.lock[0].name == "lock-CanNotDelete" &&
      azapi_resource.lock[0].body.properties.level == "CanNotDelete" &&
      azapi_resource.lock[0].body.properties.notes == "Cannot delete the resource or its child resources."
    )
    error_message = "The interfaces upgrade must preserve the lock name, level, and notes."
  }

  assert {
    condition = (
      azapi_resource.role_assignments["reader"].name == var.role_assignments.reader.name &&
      azapi_resource.role_assignments["reader"].body.properties.principalId == var.role_assignments.reader.principal_id &&
      azapi_resource.role_assignments["reader"].body.properties.principalType == "ServicePrincipal" &&
      azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId == var.role_assignments.reader.role_definition_id_or_name
    )
    error_message = "The interfaces upgrade must preserve role assignment names and ARM properties."
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 1 && azapi_resource.telemetry[0].location == var.location
    error_message = "Telemetry must use the supplied location."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "interfaces_without_telemetry" {
  command = apply

  variables {
    enable_telemetry = false
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0
    error_message = "The telemetry opt-out must remain supported."
  }

  assert {
    condition = (
      azapi_resource.lock[0].name == "lock-CanNotDelete" &&
      azapi_resource.role_assignments["reader"].name == var.role_assignments.reader.name
    )
    error_message = "Opting out of telemetry must preserve lock and role assignment identities."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}
