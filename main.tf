resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.private_endpoint
  body = {
    properties = {
      applicationSecurityGroups  = [for id in var.application_security_group_association_ids : { id = id }]
      customNetworkInterfaceName = var.network_interface_name
      ipConfigurations = [
        for ip_configuration in values(var.ip_configurations) : {
          name = ip_configuration.name
          properties = {
            groupId          = ip_configuration.subresource_name
            memberName       = ip_configuration.member_name
            privateIPAddress = ip_configuration.private_ip_address
          }
        }
      ]
      privateLinkServiceConnections = [
        {
          name = var.private_service_connection_name != null ? var.private_service_connection_name : "pse-${var.name}"
          properties = {
            groupIds             = var.subresource_names
            privateLinkServiceId = var.private_connection_resource_id
          }
        }
      ]
      subnet = {
        id = var.subnet_resource_id
      }
    }
  }
  create_headers      = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers      = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes = length(var.ignore_body_changes.private_endpoint) > 0 ? var.ignore_body_changes.private_endpoint : null
  read_headers        = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = {
    ip_configurations               = var.ip_configurations
    network_interface_name          = var.network_interface_name
    private_connection_resource_id  = var.private_connection_resource_id
    private_service_connection_name = var.private_service_connection_name
    subnet_resource_id              = var.subnet_resource_id
    subresource_names               = var.subresource_names
  }
  response_export_values = {
    id         = "id"
    name       = "name"
    properties = "properties"
    type       = "type"
  }
  retry          = var.retry
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.private_endpoint.create
    delete = var.timeouts.private_endpoint.delete
    read   = var.timeouts.private_endpoint.read
    update = var.timeouts.private_endpoint.update
  }
}

module "private_dns_zone_group" {
  source = "./modules/private-dns-zone-group"
  count  = length(var.private_dns_zone_resource_ids) > 0 ? 1 : 0

  name                          = var.private_dns_zone_group_name
  private_dns_zone_resource_ids = var.private_dns_zone_resource_ids
  private_endpoint_id           = azapi_resource.this.id
  resource_type                 = var.resource_types.private_dns_zone_group
  headers                       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry                         = var.retry
  timeouts                      = var.timeouts.private_dns_zone_group
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.5.0"

  enable_telemetry                          = var.enable_telemetry
  lock                                      = var.lock
  role_assignment_definition_lookup_enabled = true
  role_assignment_definition_scope          = azapi_resource.this.id
  role_assignment_name_use_random_uuid      = var.role_assignment_name_use_random_uuid
  role_assignments                          = var.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name           = each.value.name
  parent_id      = azapi_resource.this.id
  type           = each.value.type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = {
    id               = "id"
    name             = "name"
    principalId      = "properties.principalId"
    principalType    = "properties.principalType"
    roleDefinitionId = "properties.roleDefinitionId"
    scope            = "properties.scope"
    type             = "type"
  }
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    ignore_changes = [name]
  }
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.this.id
  type      = module.avm_interfaces.lock_azapi.type
  body = {
    properties = {
      level = var.lock.kind
      notes = lookup(local.lock_notes, var.lock.kind, null)
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [time_sleep.wait_for_resource_destroy]
}

resource "time_sleep" "wait_for_resource_destroy" {
  destroy_duration = "20s"

  depends_on = [azapi_resource.this]
}
