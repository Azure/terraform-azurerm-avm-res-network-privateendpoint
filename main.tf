resource "azurerm_private_endpoint" "this" {
  location                      = var.location
  name                          = var.name
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.subnet_resource_id
  custom_network_interface_name = var.network_interface_name
  tags                          = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = var.private_service_connection_name != null ? var.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = var.subresource_names
  }
  dynamic "ip_configuration" {
    for_each = var.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = ip_configuration.value.member_name
      subresource_name   = ip_configuration.value.subresource_name
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = var.private_dns_zone_group_name
      private_dns_zone_ids = var.private_dns_zone_resource_ids
    }
  }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = var.application_security_group_association_ids

  application_security_group_id = each.value
  private_endpoint_id           = azurerm_private_endpoint.this.id
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_private_endpoint.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_private_endpoint.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
