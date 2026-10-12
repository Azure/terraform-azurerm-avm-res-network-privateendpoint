terraform-azurerm-avm-res-network-privateendpoint

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
> 
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
> 
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

## Upgrading from a version that used the AzureRM provider

This version manages the private endpoint with AzAPI and includes migration blocks for the private endpoint, role assignments, application security group associations, and locks. Run `terraform init -upgrade`, then `terraform plan`. Expect in-place updates while AzAPI takes over existing resources and new `random_uuid` resources when role assignments are configured. Do not apply a plan that destroys or replaces the private endpoint, lock, or role assignments.

Two cases need extra steps:

- **Private DNS zone groups.** The private DNS zone group is now managed by a submodule because it is a child resource of the private endpoint. If you set `private_dns_zone_resource_ids`, import the existing DNS zone group at its new address before applying:

  ```hcl
  import {
    to = module.<module-name>.module.private_dns_zone_group[0].azapi_resource.this
    id = "<private endpoint resource ID>/privateDnsZoneGroups/<private DNS zone group name>"
  }
  ```

- **`ReadOnly` lock.** The upgrade updates the private endpoint in place, which a `ReadOnly` lock blocks. Before upgrading, apply your configuration with `lock = null` using the old version, then upgrade and restore the lock.
