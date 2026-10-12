locals {
  # Preserve the lock notes written by the AzureRM implementation so upgrades do not drift existing locks.
  lock_notes = {
    CanNotDelete = "Cannot delete the resource or its child resources."
    ReadOnly     = "Cannot delete or modify the resource or its child resources."
  }
  private_dns_zone_group_imports = var.avm_managed_migration_enabled && length(var.private_dns_zone_resource_ids) > 0 ? {
    this = "${azapi_resource.this.id}/privateDnsZoneGroups/${local.private_dns_zone_group_name}"
  } : {}
  private_dns_zone_group_name = coalesce(var.private_dns_zone_group_name, "default")
}
