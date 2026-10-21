mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateEndpoints/example/privateDnsZoneGroups/default"
      output = {
        private_dns_zone_configs = [{
          name = "example"
          etag = "example-etag"
          properties = {
            privateDnsZoneId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
          }
        }]
      }
    }
  }
}

mock_provider "time" {}

variables {
  location  = "eastus"
  name      = "default"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateEndpoints/example"
  private_dns_zone_resource_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net",
  ]
}

run "telemetry_enabled" {
  command = apply

  module {
    source = "./modules/private-dns-zone-group"
  }

  assert {
    condition = alltrue([
      azapi_resource.this.create_headers == null,
      azapi_resource.this.read_headers == null,
      azapi_resource.this.update_headers == null,
      azapi_resource.this.delete_headers == null,
    ])
    error_message = "Telemetry must not add request headers to the DNS zone group."
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 1
    error_message = "Telemetry must remain enabled by default through its separate deployment."
  }
}

run "telemetry_disabled" {
  command = apply

  module {
    source = "./modules/private-dns-zone-group"
  }

  variables {
    enable_telemetry = false
  }

  assert {
    condition = alltrue([
      azapi_resource.this.create_headers == null,
      azapi_resource.this.read_headers == null,
      azapi_resource.this.update_headers == null,
      azapi_resource.this.delete_headers == null,
    ])
    error_message = "Opting out of telemetry must not change DNS zone group request headers."
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0
    error_message = "Opting out must disable the separate telemetry deployment."
  }

  assert {
    condition     = output.resource_id == run.telemetry_enabled.resource_id
    error_message = "Opting out of telemetry must preserve the DNS zone group resource ID."
  }

  assert {
    condition     = output.private_dns_zone_configs == run.telemetry_enabled.private_dns_zone_configs
    error_message = "Opting out of telemetry must preserve the exported DNS configuration."
  }
}
