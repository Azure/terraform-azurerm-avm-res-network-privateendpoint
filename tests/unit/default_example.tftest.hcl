mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000001"
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      output = { private_ip_addresses = ["10.0.1.4"] }
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

mock_provider "random" {
  mock_resource "random_integer" {
    defaults = {
      result = 0
    }
  }

  mock_resource "random_string" {
    defaults = {
      result = "abcdefgh12345678"
    }
  }
}

mock_provider "time" {}

override_resource {
  target = azapi_resource.resource_group
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
  }
}

override_resource {
  target = azapi_resource.key_vault
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.KeyVault/vaults/example"
  }
}

override_resource {
  target = azapi_resource.virtual_network
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example"
  }
}

override_resource {
  target = azapi_resource.subnet
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example/subnets/default"
  }
}

run "default_example" {
  command = apply

  module {
    source = "./examples/default"
  }

  assert {
    condition = (
      azapi_resource.resource_group.location == module.regions.regions[random_integer.region_index.result].name &&
      azapi_resource.resource_group.name == module.naming.names.resource_group.name_unique &&
      azapi_resource.key_vault.name == module.naming.names.key_vault_vault.name_unique &&
      azapi_resource.virtual_network.name == module.naming.names.virtual_network.name_unique &&
      azapi_resource.subnet.name == module.naming.names.virtual_network_subnet.name_unique &&
      module.test.name == module.naming.names.private_endpoint.name_unique
    )
    error_message = "The example must use the selected region and modern naming outputs."
  }

  assert {
    condition = (
      azapi_resource.key_vault.parent_id == azapi_resource.resource_group.id &&
      azapi_resource.key_vault.body.properties.enableRbacAuthorization &&
      azapi_resource.key_vault.body.properties.enablePurgeProtection &&
      azapi_resource.key_vault.body.properties.networkAcls.defaultAction == "Deny" &&
      azapi_resource.subnet.parent_id == azapi_resource.virtual_network.id &&
      azapi_resource.subnet.body.properties.privateEndpointNetworkPolicies == "Enabled"
    )
    error_message = "The example must retain its Key Vault security and subnet settings."
  }

  assert {
    condition = (
      module.test.resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateEndpoints/example" &&
      module.test.private_ip_addresses == ["10.0.1.4"]
    )
    error_message = "The example must return the private endpoint ID and private IP address."
  }
}
