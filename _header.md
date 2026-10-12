terraform-azurerm-avm-res-network-privateendpoint

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
> 
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
> 
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

## Upgrading from a version that used the AzureRM provider

This version manages the private endpoint with AzAPI and includes migration blocks for the private endpoint, role assignments, application security group associations, private DNS zone groups, and locks. Terraform 1.16 or later is required because the module uses opt-in managed import blocks for AzureRM inline resources that now have AzAPI child-resource addresses.

Run `terraform init -upgrade`, set `avm_managed_migration_enabled = true`, then run `terraform plan`. Expect in-place updates while AzAPI takes over existing resources and new `random_uuid` resources when role assignments are configured. Do not apply a plan that destroys or replaces the private endpoint, lock, role assignments, or private DNS zone group.

The private DNS zone group is now managed by a submodule because it is a child resource of the private endpoint. If you set `private_dns_zone_resource_ids`, `avm_managed_migration_enabled = true` causes the module to import the existing DNS zone group into `module.private_dns_zone_group[0].azapi_resource.this` during the migration apply. The import ID is built from the private endpoint ID and `private_dns_zone_group_name`; when `private_dns_zone_group_name` is not set, the module uses `default`.

After one successful migration apply and a clean follow-up plan, set `avm_managed_migration_enabled = false` again.

One case still needs an extra step:

- **`ReadOnly` lock.** The upgrade updates the private endpoint in place, which a `ReadOnly` lock blocks. Before upgrading, apply your configuration with `lock = null` using the old version, then upgrade and restore the lock after the migration.
