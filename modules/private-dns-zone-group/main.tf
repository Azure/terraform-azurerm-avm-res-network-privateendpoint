resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  body = {
    properties = {
      privateDnsZoneConfigs = [
        for private_dns_zone_resource_id in var.private_dns_zone_resource_ids : {
          name = element(reverse(split("/", private_dns_zone_resource_id)), 0)
          properties = {
            privateDnsZoneId = private_dns_zone_resource_id
          }
        }
      ]
    }
  }
  create_headers      = var.headers
  delete_headers      = var.headers
  ignore_body_changes = length(var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups) > 0 ? var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups : null
  read_headers        = var.headers
  response_export_values = {
    private_dns_zone_configs = "properties.privateDnsZoneConfigs"
  }
  retry          = var.retry
  update_headers = var.headers

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
