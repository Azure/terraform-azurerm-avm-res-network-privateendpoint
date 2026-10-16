terraform-azurerm-avm-res-network-privateendpoint

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
> 
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
> 
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

## Upgrading from a version that used the AzureRM provider

This version manages the private endpoint with AzAPI and includes migration blocks for the private endpoint, role assignments, application security group associations, private DNS zone groups, and locks. Terraform 1.16 or later is required because the module uses opt-in managed import blocks for AzureRM inline resources that now have AzAPI child-resource addresses.

Before upgrading, update the consumer configuration:

- Replace `resource_group_name` with the required `parent_id` resource-group ID.
- Replace uses of the whole `resource` output with the discrete `name`, `resource_id`, `private_ip_addresses`, or `network_interface_ids` outputs. The old AzureRM-shaped object is no longer exposed. `private_ip_addresses` is read from the private endpoint network interface, including dynamically assigned addresses when a private DNS zone group is configured.
- Remove `role_assignment_name_use_random_uuid`; the module now uses `Azure/avm-utl-interfaces` 0.7.0. Existing AzureRM role-assignment GUIDs are preserved during migration.
- Pass `application_security_group_association_ids` as before. The associations are represented in the private endpoint body and the old standalone association state is detached without destroying the Azure relationship.

Keep the AzureRM provider configuration in the consumer root through the migration apply so Terraform can process the old AzureRM state. Run `terraform init -upgrade`, set `avm_managed_migration_enabled = true`, then run `terraform plan`. Expect in-place updates while AzAPI takes over existing resources. Do not apply a plan that destroys or replaces the private endpoint, lock, role assignments, application security group associations, or private DNS zone group.

The private DNS zone group is now managed by a submodule because it is a child resource of the private endpoint. If you set `private_dns_zone_resource_ids`, `avm_managed_migration_enabled = true` causes the module to import the existing DNS zone group into `module.private_dns_zone_group[0].azapi_resource.this` during the migration apply. The import ID is built from the private endpoint ID and `private_dns_zone_group_name`; when `private_dns_zone_group_name` is not set, the module uses `default`.

After one successful migration apply, verify the private endpoint ID and configured ASG associations remain unchanged, then run a clean follow-up plan. Set `avm_managed_migration_enabled = false` again after that plan is clean.

Two cases still need extra steps:

- **`ReadOnly` lock.** The upgrade updates the private endpoint in place, which a `ReadOnly` lock blocks. Before upgrading, apply your configuration with `lock = null` using the old version, then upgrade and restore the lock after the migration.
- **Cross-tenant role assignments** (those that set `delegated_managed_identity_resource_id`, such as Azure Lighthouse). The AzureRM provider stored these role-assignment IDs with a `|<tenant-id>` suffix that the `moved` block cannot convert. Before planning the upgrade, remove each affected assignment from state, then import it at the AzAPI address from the consumer root:

  ```pwsh
  terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
  ```

  ```hcl
  import {
    to = module.<module-name>.azapi_resource.role_assignments["<key>"]
    id = "<role assignment ARM resource ID, without the |<tenant-id> suffix>"
  }
  ```

  Keep the assignment's existing ARM resource ID and GUID. Confirm the import is planned without creating or deleting the assignment before applying the migration.
