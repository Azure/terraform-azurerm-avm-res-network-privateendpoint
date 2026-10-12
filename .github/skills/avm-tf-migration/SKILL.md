---
name: avm-tf-migration
description: Use for AVM Terraform AzureRM-to-AzAPI migrations, state preservation, moved blocks, provider state moves, submodule extraction, upgrade tests, and post-migration specification compliance.
---

# AVM Terraform Migration

An AzureRM-to-AzAPI migration is complete only when the implementation satisfies the current AVM specifications and existing consumers have a documented, tested state path.

Migration guidance applies to existing modules only. AzureRM may be read, analyzed, and referenced as source input being migrated, including legacy `azurerm_*` state addresses. Generated target code uses AzAPI for every control-plane and supported Azure operation.

The target rule includes implementation, submodules, upgrade examples, E2E configurations, Terraform tests, fixtures, setup or teardown Terraform, documentation examples, and generated snippets. Supporting control-plane resources use AzAPI, and each standalone target Terraform root includes `Azure/azapi` in `required_providers`. Retain an `azurerm_*` resource or data-source block only when that block independently implements one specific unsupported data-plane/non-ARM operation. Document the exact block and why AzAPI cannot implement it with an upstream AzAPI issue or pull request, and replace the block when support ships. One valid block does not authorize another.

Read TFFR3-TFFR8, TFRMFR1, TFRMNFR1, TFRMNFR2, TFNFR38, and TFNFR39 through <https://azure.github.io/Azure-Verified-Modules/llms.txt> before choosing the migration shape.

## Separate two changes

Treat these as different graph migrations:

1. **Provider migration in place:** `azurerm_*` to an AzAPI resource at the same module/cardinality boundary.
2. **Composition migration:** moving a resource across a module boundary, such as extracting a root collection into `module.child[each.key].azapi_resource.this`.

Combining them makes state preservation harder and can make a reusable `moved` block impossible. Prefer migrating the provider in place first, releasing that state path, and extracting to a submodule in a later breaking release when needed.

## Cardinality rule

TFRMNFR1 requires the parent module to own `count` or `for_each`. A submodule's primary resource manages one instance:

```hcl
module "part" {
  source   = "./modules/part"
  for_each = var.parts
}
```

```hcl
# modules/part/main.tf
resource "azapi_resource" "this" {
  # No count or for_each here.
}
```

Do not move `for_each` inside the submodule to make state addresses easier. That violates the target design.

A root collection address such as:

```text
azurerm_example_part.this["a"]
```

becomes:

```text
module.part["a"].azapi_resource.this
```

Terraform cannot express a generic key-preserving resource-to-module move for every unknown consumer key. Options are:

- migrate the provider at the existing boundary first;
- migrate a resource already inside an existing `for_each` module call;
- publish explicit consumer `terraform state mv` instructions for known keys; or
- accept and document a breaking state migration when extraction itself is required.

Never hide a state-breaking extraction behind a claim that a wildcard `moved` block preserves it.

## Provider migration in place

When the providers support the state move, use a declarative block:

```hcl
moved {
  from = azurerm_example_widget.this
  to   = azapi_resource.this
}
```

For a same-level collection, moving the resource address can preserve its instances. Verify this against applied state; do not assume provider state conversion supports every resource.

Keep migration blocks for the documented compatibility window and release them with clear upgrade notes. Use direct `terraform state mv` only when no reusable declarative move exists, and provide PowerShell-friendly instructions:

```pwsh
terraform state list
terraform state mv 'azurerm_example_part.this["a"]' 'module.part["a"].azapi_resource.this'
```

Back up state before imperative changes.

## State transition mechanism selection

Choose the state mechanism from the relationship between the old Terraform state address, the new Terraform state address, and the existing Azure object:

- Use `moved` when an old Terraform address has a direct new Terraform address, such as the primary resource moving from `azurerm_example_widget.this` to `azapi_resource.this`, or role assignments and locks moving to AzAPI resources at the same cardinality boundary.
- Use `removed { destroy = false }` when an old Terraform address disappears because the remote object is intentionally represented elsewhere, such as a legacy child/association resource that is now folded into the parent AzAPI resource body.
- Use `import` when an existing Azure object needs a new Terraform address but did not previously have a standalone Terraform state address, such as an AzureRM inline block that becomes an AzAPI child resource submodule.

Do not import every auxiliary resource by default. Import only newly addressed existing remote objects that cannot be represented with a `moved` block and should remain under Terraform management.

Example folded-resource removal:

```hcl
removed {
  from = azurerm_example_association.this

  lifecycle {
    destroy = false
  }
}
```

Example parent-body representation:

```hcl
resource "azapi_resource" "this" {
  body = {
    properties = {
      associations = [for id in var.association_ids : { id = id }]
    }
  }
}
```

## Module-owned managed migration imports

Prefer module-owned, opt-in imports over asking consumers to hand-write root-module import blocks when all of these are true:

1. the module can deterministically construct the existing Azure resource ID from its inputs and newly moved parent resource;
2. the target address is inside the module or one of its submodules;
3. the source object did not have a standalone old Terraform state address; and
4. the migration can be safely disabled after the upgrade.

Gate these imports behind a temporary boolean named `avm_managed_migration_enabled`, defaulting to `false`:

```hcl
variable "avm_managed_migration_enabled" {
  type        = bool
  default     = false
  description = "Enables module-owned migration helpers for upgrading from earlier AzureRM-backed versions. Set to true only during the upgrade apply, then set back to false."
  nullable    = false
}
```

Terraform `import` blocks with `for_each` require Terraform 1.16 or later. If a module adopts this pattern, update every affected `required_version` constraint and upgrade documentation deliberately, for example:

```hcl
terraform {
  required_version = ">= 1.16, < 2.0"
}
```

Use an empty `for_each` when the migration flag is disabled or the source object is not configured:

```hcl
import {
  for_each = var.avm_managed_migration_enabled && length(var.child_resource_ids) > 0 ? {
    this = "${azapi_resource.this.id}/childResources/${var.child_resource_name}"
  } : {}

  to = module.child_resource[0].azapi_resource.this
  id = each.value
}
```

Document the lifecycle clearly: consumers set `avm_managed_migration_enabled = true` for the migration plan/apply, verify no unintended destroy or replacement actions, apply, run a clean follow-up plan, then set it back to `false`.

Do not use this flag for ordinary feature toggles, steady-state configuration, or resources that can be preserved with a normal `moved` block.

## Target implementation checklist

The AzAPI target must include:

- `Azure/azapi ~> 2.12`;
- primary resource label `this`;
- required `parent_id` and TFNFR38 resource ID validation;
- standard TFNFR39 files in root and submodules;
- `type` from the deterministic `resource_types` object;
- `response_export_values`, including an explicit empty value;
- `replace_triggers_refs` only when replacement paths exist, using a non-empty static list of unique, valid JMESPath body paths;
- consumer-configurable `retry` and dynamic `timeouts`;
- per-resource `ignore_body_changes` with empty lists collapsed to `null`;
- nested `resource_types` and `ignore_body_changes` slots for submodules;
- discrete outputs mapped from `azapi_resource.this.output`; and
- standard interfaces composed through `Azure/avm-utl-interfaces/azure ~> 0.6`.

Do not retain AzureRM as a convenience fallback or copy it into target examples and tests. Existing AzureRM configuration is migration input only, except when the target still requires the narrowly documented unsupported data-plane/non-ARM operation.

## AzureRM-to-AzAPI review hazards

Check these hazards explicitly during remediation reviews:

- **ForceNew-equivalent fields:** AzureRM may have forced replacement for fields that become AzAPI body properties. Preserve replacement semantics with `replace_triggers_external_values` when body paths are unstable, Azure-normalized, or null immediately after provider state conversion. Use input values rather than computed body paths when that avoids first-plan false replacements after `moved` blocks.
- **Invalid ARM child types:** Some AzureRM helper resources are not real ARM child resource types. Do not model them as AzAPI resources unless the ARM type exists and plans successfully. Fold them into the parent body, use `removed { destroy = false }` for the old address, and test with non-default interface inputs that exercise the path.
- **Subresource extraction:** ARM subresources become TFRMNFR1 submodules. If the old implementation modeled the child inline, use module-owned conditional imports or explicit consumer import guidance; a `moved` block cannot move an inline nested block that never had its own state address.
- **Role assignment names:** Upgraded role assignments often keep AzureRM-generated GUIDs while the interface module computes new names. Add `lifecycle { ignore_changes = [name] }` when replacing names would delete and recreate existing assignments.
- **Locks:** Preserve legacy lock default names and notes so upgrades do not rename or drift locks. Document that `ReadOnly` locks block in-place PUT updates; consumers must remove them before migration and restore them afterward.
- **ScopeLocked destroy ordering:** A deleted `CanNotDelete` lock can continue to be enforced briefly. When a module manages locks and protected child resources, make any lock-removal sleep conditional on a lock being configured and depend on every resource protected by that lock, not only the primary resource.
- **Coverage:** Add or update examples/tests that exercise locks, role assignments, subresources, associations, and other optional interfaces. Default bare-resource examples are insufficient migration evidence.

## Ignore semantics during migration

Static Terraform lifecycle references remain expressions:

```hcl
lifecycle {
  ignore_changes = [name]
}
```

Use this for compile-time-static resource attributes, including a migration case where an imported server-assigned role-assignment name must remain stable.

Use TFFR8 `ignore_body_changes` for consumer-selected body paths:

```hcl
ignore_body_changes = length(var.ignore_body_changes.example_widgets) > 0 ? var.ignore_body_changes.example_widgets : null
```

Paths are body-relative dot notation, cannot target list indices, and prevent ignored configuration from being sent to Azure. A change to the provider-private value takes effect only after apply.

## Upgrade-path validation

Test against real state:

1. deploy a representative example with the latest published pre-migration module;
2. capture `terraform state list` and a state backup;
3. switch the example to the local migrated module;
4. run `terraform init -upgrade`;
5. run `terraform plan` and require zero unintended destroys or replacements;
6. apply the migration;
7. run a second plan and require no changes;
8. verify discrete outputs and all supported interfaces; and
9. destroy through the migrated implementation.

Use `avm test integration` for real-Azure Terraform tests and `avm test e2e --example <name>` for an example deployment. Run `avm pre-commit`, commit all results, and then run `avm pr-check` on a clean worktree.

If state cannot be preserved, classify the change correctly under the current breaking-change and semantic-versioning specifications. Document exact consumer commands and expected effects rather than silently accepting recreation.
