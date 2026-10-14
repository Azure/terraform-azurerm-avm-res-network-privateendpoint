variable "location" {
  type        = string
  description = "(Required) Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) The name of the this resource."
}

variable "network_interface_name" {
  type        = string
  description = "(Optional) The custom name of the network interface attached to the private endpoint. Changing this forces a new resource to be created"
}

variable "parent_id" {
  type        = string
  description = "The Azure resource ID of the parent resource group, in the form `/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}`."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "The parent_id must be a valid Azure resource group resource ID."
  }
}

variable "private_connection_resource_id" {
  type        = string
  description = "(Required) The ID of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to."
}

variable "subnet_resource_id" {
  type        = string
  description = "(Required) Azure resource ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.subnet_resource_id))
    error_message = "`subnet_resource_id` must be a valid subnet resource ID."
  }
}

variable "application_security_group_association_ids" {
  type        = set(string)
  default     = []
  description = "(Optional) The resource ids of application security group to associate."
  nullable    = false

  validation {
    condition = alltrue([
      for id in var.application_security_group_association_ids :
      can(provider::azapi::parse_resource_id("Microsoft.Network/applicationSecurityGroups", id))
    ])
    error_message = "Each `application_security_group_association_ids` entry must be a valid application security group resource ID."
  }
}

variable "avm_managed_migration_enabled" {
  type        = bool
  default     = false
  description = "Enables module-owned migration helpers for upgrading from earlier AzureRM-backed versions. Set to true only during the upgrade apply, then set back to false."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    authorization_locks            = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
    network_private_endpoints      = optional(list(string), [])
    network_private_endpoints_private_dns_zone_groups = optional(object({
      network_private_endpoints_private_dns_zone_groups = optional(list(string), [])
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot-notation paths the AzAPI provider ignores for each resource. Ignored configuration is not sent to Azure until the path is removed. Changes take effect only after apply. A non-empty value requires Terraform 1.11 or later.

- `authorization_locks` - Ignored paths for the lock.
- `authorization_role_assignments` - Ignored paths for role assignments.
- `network_private_endpoints` - Ignored paths for the private endpoint.
- `network_private_endpoints_private_dns_zone_groups` - Override slot for the DNS zone group submodule.
  - `network_private_endpoints_private_dns_zone_groups` - Ignored paths for the DNS zone group.
DESCRIPTION
  nullable    = false
}

variable "ip_configurations" {
  type = map(object({
    name               = string
    private_ip_address = string
    subresource_name   = string
    member_name        = optional(string, "default")
  }))
  default     = {}
  description = <<DESCRIPTION
  (Optional) An ip_configuration block as defined below
  map(object({
    private_ip_address = "(Required) Specifies the static IP address within the private endpoint's subnet to be used. Changing this forces a new resource to be created."
    subresource_name   = "(Required) Specifies the subresource this IP address applies to."
    member_name        = "(Optional) Specifies the member name this IP address applies to."
  }))

  Example Input:

  ```terraform
  ip_configurations ={
    "object1" = {
      name               = "<name_of_the_ip_configuration>"
      private_ip_address = "<value_of_the_static_IP >"
      subresource_name   = "<subresource_name>"
    }
  }
  ``` 
  DESCRIPTION
}

variable "lock" {
  type = object({
    kind  = string
    name  = optional(string, null)
    notes = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the resource lock configuration for this private endpoint.

- `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
- `name` - (Optional) The lock name. If omitted, the module preserves the previous `lock-<kind>` name.
- `notes` - (Optional) Notes written to `Microsoft.Authorization/locks.properties.notes`. The module preserves its previous default notes when omitted.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `CanNotDelete` or `ReadOnly`."
  }
}

variable "private_dns_zone_group_name" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Name of the Private DNS Zone Group."
}

variable "private_dns_zone_resource_ids" {
  type        = list(string)
  default     = []
  description = "(Optional) Specifies the list of Private DNS Zones to include within the private_dns_zone_group."
  nullable    = false

  validation {
    condition = alltrue([
      for id in var.private_dns_zone_resource_ids :
      can(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", id))
    ])
    error_message = "Each `private_dns_zone_resource_ids` entry must be a valid private DNS zone resource ID."
  }
}

variable "private_service_connection_name" {
  type        = string
  default     = null
  description = "(Optional) Specifies the  Specifies the Name of the Private Service Connection."
}

variable "resource_types" {
  type = object({
    authorization_locks            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    network_private_endpoints      = optional(string, "Microsoft.Network/privateEndpoints@2025-07-01")
    network_private_endpoints_private_dns_zone_groups = optional(object({
      network_private_endpoints_private_dns_zone_groups = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this module and its submodule. Supply only the keys to override.

- `authorization_locks` - The management lock.
- `authorization_role_assignments` - Role assignments on the private endpoint.
- `network_private_endpoints` - The private endpoint.
- `network_private_endpoints_private_dns_zone_groups` - Overrides for the private DNS zone group submodule.
  - `network_private_endpoints_private_dns_zone_groups` - The private DNS zone group managed by the submodule.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every AzAPI resource in this module and its submodule. Defaults to provider retry behavior.

- `error_message_regex` - (Optional) Error-message patterns that trigger a retry.
- `interval_seconds` - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See the AzAPI provider `retry` documentation for full semantics.
DESCRIPTION
}

variable "role_assignments" {
  type = map(object({
    name                                   = optional(string, null)
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this private endpoint. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

- `name` - (Optional) The role assignment GUID. If omitted, the interfaces module generates one. During migration, existing AzureRM names are preserved.
- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.  

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Example Input:

  ```terraform
  role_assignments ={
    "object1" = {
      role_definition_id_or_name = "<role_definition_1_name>"
      principal_id               = "<object_id_of_the_principal>"
    },
    "object2" = {
      role_definition_id_or_name = "<role_definition_2_name>"
      principal_id               = "<object_id_of_the_principal>"
      description                = "<description>"
    },
  }
  ``` 
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for _, assignment in var.role_assignments :
      assignment.delegated_managed_identity_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", assignment.delegated_managed_identity_resource_id))
    ])
    error_message = "Each `role_assignments[*].delegated_managed_identity_resource_id` must be a valid user-assigned managed identity resource ID, or null."
  }
}

variable "subresource_names" {
  type        = list(string)
  default     = null
  description = "(Optional) A list of subresource names which the Private Endpoint is able to connect to. [https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource]"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to be applied to the resource"
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every AzAPI resource in this module and its submodule. Defaults to provider timeouts. Values are Go duration strings such as `30m` or `1h`.

- `create` - (Optional) Timeout for create operations.
- `read` - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
