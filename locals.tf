locals {
  # Preserve the lock notes written by the AzureRM implementation so upgrades do not drift existing locks.
  lock_notes = {
    CanNotDelete = "Cannot delete the resource or its child resources."
    ReadOnly     = "Cannot delete or modify the resource or its child resources."
  }
  lock = var.lock == null ? null : merge(var.lock, {
    name  = coalesce(var.lock.name, "lock-${var.lock.kind}")
    notes = coalesce(var.lock.notes, local.lock_notes[var.lock.kind])
  })

  role_definition_resource_substring = "/providers/microsoft.authorization/roledefinitions/"
  role_definition_ids_by_name = length(var.role_assignments) > 0 ? {
    for definition in data.azapi_resource_list.role_definitions[0].output.results :
    lower(definition.role_name) => definition.id...
  } : {}
  role_assignments = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      principal_type = assignment.principal_type == null && assignment.skip_service_principal_aad_check ? "ServicePrincipal" : assignment.principal_type
      role_definition_id_or_name = (
        !strcontains(lower(assignment.role_definition_id_or_name), local.role_definition_resource_substring) ?
        try(local.role_definition_ids_by_name[lower(assignment.role_definition_id_or_name)][0], assignment.role_definition_id_or_name) :
        startswith(lower(assignment.role_definition_id_or_name), "/providers/") ?
        "/subscriptions/${local.subscription_id}${assignment.role_definition_id_or_name}" :
        assignment.role_definition_id_or_name
      )
    })
  }
  subscription_id = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).subscription_id

  private_dns_zone_group_imports = var.avm_managed_migration_enabled && length(var.private_dns_zone_resource_ids) > 0 ? {
    this = "${azapi_resource.this.id}/privateDnsZoneGroups/${local.private_dns_zone_group_name}"
  } : {}
  private_dns_zone_group_name = coalesce(var.private_dns_zone_group_name, "default")
}
