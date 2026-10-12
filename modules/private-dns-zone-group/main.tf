resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.private_endpoint_id
  type      = var.resource_type
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
  create_headers = var.headers
  delete_headers = var.headers
  read_headers   = var.headers
  response_export_values = {
    id         = "id"
    name       = "name"
    properties = "properties"
    type       = "type"
  }
  retry          = var.retry
  update_headers = var.headers

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }
}
