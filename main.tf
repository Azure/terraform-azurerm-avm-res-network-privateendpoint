resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.network_private_endpoints
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
  ignore_body_changes = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
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

data "azapi_resource_list" "role_definitions" {
  count = length(var.role_assignments) > 0 ? 1 : 0

  parent_id = var.parent_id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

module "private_dns_zone_group" {
  source = "./modules/private-dns-zone-group"
  count  = length(var.private_dns_zone_resource_ids) > 0 ? 1 : 0

  name                          = local.private_dns_zone_group_name
  parent_id                     = azapi_resource.this.id
  private_dns_zone_resource_ids = var.private_dns_zone_resource_ids
  headers                       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes           = var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups
  resource_types                = var.resource_types.network_private_endpoints_private_dns_zone_groups
  retry                         = var.retry
  timeouts                      = var.timeouts
}

import {
  for_each = local.private_dns_zone_group_imports

  to = module.private_dns_zone_group[0].azapi_resource.this
  id = each.value
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.7.0"

  enable_telemetry                          = var.enable_telemetry
  lock                                      = local.lock
  role_assignment_definition_lookup_enabled = false
  role_assignments                          = local.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name                 = module.avm_interfaces.role_assignments_azapi[each.key].name
  parent_id            = azapi_resource.this.id
  type                 = var.resource_types.authorization_role_assignments
  body                 = module.avm_interfaces.role_assignments_azapi[each.key].body
  create_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes  = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  ignore_casing        = true
  ignore_null_property = true
  read_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = {
    condition                              = each.value.condition
    condition_version                      = each.value.condition_version
    delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
    description                            = each.value.description
    principal_id                           = lower(each.value.principal_id)
    principal_type                         = local.role_assignments[each.key].principal_type
    role_definition_id_or_name             = lower(each.value.role_definition_id_or_name)
  }
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    ignore_changes = [name]

    precondition {
      condition     = strcontains(lower(local.role_assignments[each.key].role_definition_id_or_name), local.role_definition_resource_substring)
      error_message = "Role definition `${each.value.role_definition_id_or_name}` was not found. Use an assignable role name or a role definition resource ID."
    }
  }
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name                   = local.lock.name
  parent_id              = azapi_resource.this.id
  type                   = var.resource_types.authorization_locks
  body                   = module.avm_interfaces.lock_azapi.body
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [time_sleep.wait_for_resource_destroy]
}

resource "time_sleep" "wait_for_resource_destroy" {
  count = var.lock != null ? 1 : 0

  destroy_duration = "30s"

  depends_on = [
    azapi_resource.this,
    azapi_resource.role_assignments,
    module.private_dns_zone_group,
  ]
}
